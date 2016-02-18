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

# repo destination vars (use only local hosts!)
USER="mikeyd"
HOST="archboxmtd"

if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# reset source command for while loop
src_cmd="

# build dirs
export build_dir="/home/desktop/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

# upstream URL
git_url="https://github.com/plexinc/plex-media-player"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
BUILDER="pdebuild"
BUILDOPTS=""
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgname="PlexMediaPlayer"
pkgver="${date_short}"
BUILDER="pdebuild"
BUILDOPTS=""
pkgrev="1"
pkgsuffix="git+bsos${pkgrev}"
dist_rel="brewmaster"
maintainer="ProfessorKaos64"
provides="plexmediaplayer"


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
        cp -r ""$scriptdir/debian"" "${git_dir}"
		
	# enter git dir
	cd "$git_dir"
	
	#################################################
	# Build PMP source
	#################################################
	
	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${pkgname}"

	# enter source dir
	cd "${pkgname}"

	commits_full=$(git log --pretty=format:"  * %cd %h %s")

	# Create basic changelog format
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname (${pkgver}+${pkgsuffix}) $dist_rel; urgency=low
	
	  * Packaged deb for SteamOS-Tools
	  * See: packages.libregeek.org
	  * Upstream authors and source: $git_url

	 -- $uploader  $date_long

	EOF

	# Perform a little trickery to update existing changelog or create
	# basic file
	cat 'changelog.in' | cat - debian/changelog > temp && mv temp debian/changelog

	# open debian/changelog and update
	echo -e "\n==> Opening changelog for confirmation/changes."
	sleep 3s
	nano "debian/changelog"

 	# cleanup old files
 	rm -f changelog.in
 	rm -f debian/changelog.in
	
	echo -e "\n==> Building Debian package from source\n"
	sleep 2s

	${BUILDER} ${BUILDOPTS}

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
	
	if [[ -d "$git_dir/build" ]]; then
	
		echo -e "Showing contents of: $git_dir/build: \n"
		ls "$git_dir/build" | grep -E "${pkgver}" *.deb
	
	elif [[ -d "${build_dir}" ]]; then
	
		echo -e "Showing contents of: $build_dir: \n"
		ls "${git_dir}/build" | grep -E "${pkgver}" *.deb

	fi

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice
	
	if [[ "$transfer_choice" == "y" ]]; then
	
		# transfer files
		if [[ -d "$git_dir/build" ]]; then
		
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${git_dir}/ ${USER}@${HOST}:${REPO_FOLDER}
		
		elif [[ -d "${build_dir}" ]]; then
		
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

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
