#!/bin/bash
# -------------------------------------------------------------------------------
# Author:    	  Michael DeGuzis
# Git:	    	  https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	  build-plex-media-player.sh
# Script Ver:	  0.1.5
# Description:	  Attempts to build a deb package from Plex Media Player git source
#                 PLEASE NOTE THIS SCRIPT IS NOT YET COMPLETE!
# See:		 
# Usage:
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

	# fallback to local repo pool target(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi

if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# reset source command for while loop
src_cmd=""

# build dirs
export build_dir="/home/desktop/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

# upstream URL
git_url="https://github.com/plexinc/plex-media-player"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="false"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgname="plexmediaplayer"
pkgver="${date_short}"
BUILDER="pdebuild"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgrev="1"
pkgsuffix="git+bsos"
DIST="brewmaster"
urgency="low"
maintainer="ProfessorKaos64"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install needed packages from Debian repos
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall \
	debian-keyring debian-archive-keyring ninja-build mesa-common-dev python-pkgconfig \
	libmpv-dev libsdl2-dev libcec-dev
	
	# built for Libregeek, specifically for this build
	sudo apt-get install -y --force-yes cmake mpv

}

main()
{
	clear
	
	#################################################
	# Fetch source
	#################################################
	
	# create and enter build_dir
	if [[ -d "${build_dir}" ]]; then
	
		sudo rm -rf "${build_dir}"
		mkdir -p "${build_dir}"
		
	else

		mkdir -p "${build_dir}"
		
	fi
	
	# Enter build dir
	cd "${build_dir}"
	
	# install prereqs for build
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi
	
	#################################################
	# Build QT 5.6 alpha source
	#################################################

	cd merge ${HOME}
	git clone https://github.com/ProfessorKaos64/qt/
	cd qt
	rm -rf debian/
	./configure -confirm-license -opensource
	make
	sudo make install
	cd qtwebengine
	qmake
	make
	sudo make install
	
	# the qt directory in /usr/local is owned by staff, correct that
	sudo chown -R root:root 
	
	#################################################
	# Fetch PMP source
	#################################################
	
	# Get upstream source
	git clone "$git_url" "$git_dir"
	
	# copy in debian folder and other files
        cp -r "$scriptdir/debian" "${git_dir}"
		
	# enter git dir
	cd "$git_dir"
	
	#################################################
	# Build PMP source
	#################################################
	
	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${src_dir}"

	# enter source dir
	cd "${src_dir}"

	commits_full=$(git log --pretty=format:"  * %cd %h %s")

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"

	fi
	
	echo -e "\n==> Building Debian package from source\n"
	sleep 2s

	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}
	
	#################################################
	# Cleanup
	#################################################
	
	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)
	
	# output finish
	echo -e "\nTime started: ${time_stamp_start}"
	echo -e "Time started: ${time_stamp_end}"
	echo -e "Total Runtime (minutes): $runtime\n"

	# inform user of packages
	cat<<-EOF
	
	###############################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependcy errors listed above.
	###############################################################
	
	Showing contents of: ${build_dir}
	
	EOF

	ls "${build_dir}" | grep -E "${pkgver}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
