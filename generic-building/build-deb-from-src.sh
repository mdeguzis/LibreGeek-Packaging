#!/bin/bash

# -------------------------------------------------------------------------------
# Author:    	Michael DeGuzis
# Git:	    	https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-deb-from-PPA.sh
# Script Ver:	0.1.7
# Description:	Attmpts to build a deb package from a git src
#
# Usage:	sudo ./build-deb-from-src.sh
#		source ./build-deb-from-src.sh
#
# See:		https://wiki.debian.org/CheckInstall
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)


# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool TARGET(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming"
	
fi

show_help()
{
	clear
	cat <<-EOF
	####################################################
	Usage:	
	####################################################
	./build-deb-from-src.sh
	./build-deb-from-src.sh --help
	source ./build-deb-from-src.sh
	
	The third option, preeceded by 'source' will 
	execute the script in the context of the calling 
	shell and preserve vars for the next run.
	
	EOF
}

if [[ "$arg" == "--help" ]]; then
	#show help
	show_help
	exit
fi

install_prereqs()
{
	clear
	echo -e "==> Assessing prerequisites for building...\n"
	sleep 1s
	# install needed packages
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall \
	debian-keyring debian-archive-keyring cmake g++ g++-multilib \
	libqt4-dev libqt4-dev libxi-dev libxtst-dev libX11-dev bc libsdl2-dev \
	gcc gcc-multilib

}

main()
{
	export BUILD_TMP="/home/desktop/build-deb-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
	GIT_DIR="$BUILD_TMP/git-tmp"
	
	clear
	# create build dir and git dir, enter it
	# mkdir -p "$GIT_DIR"
	# cd "$GIT_DIR"
	
	# Ask user for repos / vars
	echo -e "==> Please enter or paste the git URL now:"
	echo -e "[ENTER to use last: $GIT_URL]\n"
	
	# set tmp var for last run, if exists
	GIT_URL_tmp="$GIT_URL"
	if [[ "$GIT_URL" == " ]]; then
		# var blank this run, get input
		read -ep "Git source URL: " GIT_URL
	else
		read -ep "Git source URL: " GIT_URL
		# user chose to keep var value from last
		if [[ "$GIT_URL" == " ]]; then
			GIT_URL="$GIT_URL_tmp"
		else
			# keep user choice
			GIT_URL="$GIT_URL"
		fi
	fi
	
	# Clone git upstream source
	git clone "$GIT_URL" "$GIT_DIR"	
	
	#################################################
	# Build PKG
	#################################################
	
	# Output readme via less to review build notes first
	echo -e "\n==> Opening any available README.md to review build notes..."
	sleep 2s
	
	readme_file=$(find . -maxdepth 1 -type f \( -name "readme" -o -name "README" -o -name "README.md" -o -name "readme.md" \))
	
	less "$readme_file"
	
	# Ask user to enter build commands until "done" is received
	echo -e "\nPlease enter your build commands, pressing [ENTER] after each one."
	echo -e "When finished, please enter the word 'done' without quotes\n\n"
	sleep 1s
	
	while [[ "$src_cmd" != "done" ]];
	do
	
		# ignore executing src_cmd if "done"
		if [[ "$src_cmd" == "done" ]]; then
			# do nothing
			echo " > /dev/null
		else
			# Execute src cmd
			$src_cmd
		fi
		
		# capture command
		read -ep "Build CMD >> " src_cmd
		
	done
  
	############################
	# proceed to DEB BUILD
	############################
	
	echo -e "\n==> Building Debian package from source"
	echo -e "When finished, please enter the word 'done' without quotes"
	sleep 2s
	
	# build deb package
	sudo checkinstall --fstrans="no" --backup="no" \
	--PKGVERsion="$(date +%Y%m%d)+git" --deldoc="yes" --exclude="/home"

	# Alternate method
	# dpkg-buildpackage -us -uc -nc

	#################################################
	# Post install configuration
	#################################################
	
	# TODO
	
	#################################################
	# Cleanup
	#################################################
	
	# clean up dirs
	
	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)
	
	# output finish
	echo -e "\nTime started: ${time_stamp_start}"
	echo -e "Time started: ${time_stamp_end}"
	echo -e "Total Runtime (minutes): $runtime\n"

	
	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)
	
	# back out of build tmp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "${scriptdir}"
	else
		cd "${HOME}"
	fi
	
	# inform user of packages
	cat<<- EOF
	#################################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependency errors listed above.
	#################################################################

	EOF

	echo -e "Showing contents of: ${BUILD_TMP}: \n"
	ls "${BUILD_TMP}" | grep -E *${PKGVER}*

	# Ask to transfer files if debian binries are built
	# Exit out with log link to reivew if things fail.

	if [[ $(ls "${BUILD_TMP}" | grep -w "deb" | wc -l) -gt 0 ]]; then

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# uplaod local repo changelog
			cp "${GIT_DIR}/debian/changelog" "${scriptdir}/debian"

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	else

		# Output log file to sprunge (pastebin) for review
		echo -e "\n==OH NO!==\nIt appears the build has failed. See below log file:"
		cat ${BUILD_TMP}/${PKGNAME}*.build | curl -F 'sprunge=<-' http://sprunge.us

	fi

}

# start main
main

