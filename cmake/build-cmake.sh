#!/bin/bash
# -------------------------------------------------------------------------------
# Author:    	  Michael DeGuzis
# Git:	    	  https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	  build-cmake.sh
# Script Ver:	  0.7.9
# Description:	  Attempts to build a deb package from Plex Media Player git source
#                 Installs cmake to '/usr/local/bin/cmake'
# See:		  https://cmake.org/download/
# Usage:	 ./build-cmake.sh
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

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# upstream URL
git_url="https://cmake.org/cmake.git"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="cmake"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgver="3.4.1"
pkgrev="2"
pkgsuffix="git+bsos${pkgrev}"
DIST="brewmaster"
urgency="low"
maintainer="ProfessorKaos64"

# build dirs
export build_dir="/home/desktop/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install needed packages
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall \
	debhelper dpkg-dev libarchive-dev libbz2-dev libcurl4-openssl-dev libexpat1-dev \
	libjsoncpp-dev liblzma-dev libncurses5-dev procps python-sphinx qtbase5-dev zlib1g-dev

}

main()
{


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

	echo -e "\n==> Fetching upstream source\n"

	# Get upstream source
	git clone -b "v${pkgver}" "$git_url" "$git_dir"

	# copy in debian folder
	cp -r ""$scriptdir/debian"" "${git_dir}"

	#################################################
	# Build cmake source
	#################################################


	echo -e "\n==> Creating original tarball\n"sleep 2s
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${src_dir}"

	# copy in debian folder
	cp -r "$scriptdir/debian" "${git_dir}"

	# enter source dir
	cd "${src_dir}"

	# gather commits
	commits_full=$(git log --pretty=format:"  * %cd %h %s")


	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	else

		dch --create --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	fi


	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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

	# back out of build temp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "${scriptdir}"
	else
		cd "${HOME}"
	fi

	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	echo -e "Showing contents of: ${build_dir}: \n"
	ls "${build_dir}" | grep $pkgname_$pkgver

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv -e 'ssh -p ${REMOTE_PORT}' --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

main
