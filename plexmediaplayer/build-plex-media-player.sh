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
# -------------------------------------------------------------------------------

#################################################
# VARS
#################################################

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)
# reset source command for while loop
src_cmd=""

# build dirs
build_dir="/home/desktop/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

# upstream URL
git_url="https://github.com/plexinc/plex-media-player"
tarball_url=""
tarball_file=""

# package vars
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgname="PlexMediaPlayer"
pkgrel="1"
dist_rel="brewmaster"
maintainer="ProfessorKaos64"
provides="plexmediaplayer"
pkggroup="video"
requires=""
replaces=""

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
	if [[ -d "$build_dir" ]]; then
	
		sudo rm -rf "$build_dir"
		mkdir -p "$build_dir"
		
	else

		mkdir -p "$build_dir"
		
	fi
	
	# Enter build dir
	cd "$build_dir"
	
	#################################################
	# Build QT 5.6 alpha source
	#################################################

	cd $HOME
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
	
	#################################################
	# Fetch PMP source
	#################################################
	
	# Get upstream source
	git clone "$git_url" "$git_dir"
		
	# enter git dir
	cd "$git_dir"
	
	
	#################################################
	# Build PMP source
	#################################################
	
	# the qt directory in /usr/local is owned by staff, correct t hat
	sudo chown -R root:root 
	
	mkdir build
	cd build

	# Cmake must be 3.1 or higher, install Libregeek version if it does not exist
	cmake_chk=$(/usr/local/bin/cmake --version | grep "cmake version")
	
	if [[ "$cmake_chk" != "cmake version 3.3.2" ]]; then
	
		# install Libregeek cmake
		# WARNING: package will replace existing cmake!
		wget "http://packages.libregeek.org/SteamOS-Tools/pool/main/c/cmake/cmake_20151025+git+SteamOS2-1_amd64.deb"
		sudo gdebi "cmake_20151025+git+SteamOS2-1_amd64.deb"
		rm -f "cmake_20151025+git+SteamOS2-1_amd64.deb"
		
	fi
	
	/usr/local/bin/cmake -GNinja -DCMAKE_BUILD_TYPE=Debug \
	-DQTROOT=/usr/local/Qt-5.6.0 \
	-DCMAKE_INSTALL_PREFIX=output ..

	ninja-build
	
	#################################################
	# Build Debian package
	#################################################
	
	echo -e "\n==> Building Debian package from source\n"
	sleep 2s

	# use checkinstall
	sudo checkinstall --pkgname="$pkgname" --fstrans="no" --backup="no" \
	--pkgversion="$(date +%Y%m%d)+git" --pkgrelease="$pkgrel" \
	--deldoc="yes" --maintainer="$maintainer" --provides="$provides" --replaces="$replaces" \
	--pkggroup="$pkggroup" --requires="$requires" --exclude="/home"
		
	fi

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
	if [[ "$scriptdir" != "" ]]; then
		cd "$scriptdir"
	else
		cd "$HOME"
	fi
	
	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	if [[ -d "$git_dir/build" ]]; then
	
		echo -e "Showing contents of: $git_dir/build: \n"
		ls "$git_dir/build" | grep -E *.deb
	
	elif [[ -d "$build_dir" ]]; then
	
		echo -e "Showing contents of: $build_dir: \n"
		ls "${git_dir}/build" | grep -E *.deb

	fi

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice
	
	if [[ "$transfer_choice" == "y" ]]; then
	
		# transfer files
		if [[ -d "$git_dir/build" ]]; then
		
			scp ${git_dir}/build/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming
		
		elif [[ -d "$build_dir" ]]; then
		
			scp $build_dir/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

		fi
		
	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
install_prereqs
main
