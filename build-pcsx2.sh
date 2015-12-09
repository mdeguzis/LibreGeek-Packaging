#!/bin/bash

# -------------------------------------------------------------------------------
# Author:    	  Michael DeGuzis
# Git:	    	  https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	  build-pcsx2.sh
# Script Ver:	  0.3.5
# Description:	  Attempts to build a deb package from PCSX2 git source
#		  It is highly suggested to build in a 32 bit environment!!!
#		  Ref: https://github.com/ProfessorKaos64/RetroRig/pull/85
#
# See:		  https://code.google.com/p/pcsx2/wiki/CompilationGuideForLinux
# Usage:	  ./build-pcsx2.sh
# -------------------------------------------------------------------------------

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)
# reset source command for while loop
src_cmd=""

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="pcsx2.snapshot"
# pkgver auto obtained from tarball filename
# pkgver="${date_short}+git+bsos"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# build dirs
build_dir="/home/desktop/build-pcsx2-temp"
git_dir="$build_dir/pcsx2"
git_url="https://github.com/PCSX2/pcsx2"

# package vars
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install needed packages
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall \
	debian-keyring debian-archive-keyring 

	echo -e "\n==> Installing pcsx2 build dependencies...\n"
	sleep 2s

	#############################################################
	# Check for i386 environment, warn user before building
	#############################################################
	
	arch_check=$(uname -m)
	if [[ "$arch_check" != "i386" ]]; then
	
		cat <<-EOF
		WARNING! - It is highly suggested you perform this build in a 32 bit
		environment! If your build fails, please consider doing so.
	
		Proceed [y/n]?
		EOF
		sleep .5s
		read -erp "Choice: " build_choice
	
		if [[ "$build_choice" == "y" ]]; then 
		
			# 32-bit build depedencies required to build on x86_64
			sudo apt-get install -y --force-yes libaio-dev:i386 libasound2-dev:i386 \
			libbz2-dev:i386 libcg:i386 libcggl:i386 libwayland-dev:i386 libegl1-mesa-dev:i386 \
			libgl1-mesa-dev:i386 libglew-dev:i386 libglu1-mesa-dev:i386 libglu1-mesa-dev:i386 \
			libwxgtk3.0-dev:i386 libjpeg62-turbo-dev:i386 libfreetype6-dev:i386 libdirectfb-dev:i386 \
			libglib2.0-dev:i386 libavahi-client-dev:i386 libpulse-dev:i386 libsdl1.2-dev:i386 \
			libsoundtouch-dev:i386 libsparsehash-dev libwxbase3.0-dev:i386 libx11-dev:i386 \
			nvidia-cg-dev:i386 nvidia-cg-toolkit portaudio19-dev:i386 zlib1g-dev:i386 
			
		else
		
			echo -e "\nExiting..."
			sleep 1s && exit 1
			
		fi
	
	elif [[ "$arch_check" == "i386" ]]; then
	
		# Builing on 32 bit directly
		sudo apt-get install -f --force-yeslibaio-dev libpng++-dev libsoundtouch-dev \
		libwxbase3.0-dev libwxgtk3.0-dev portaudio19-dev libbz2-dev libgtk2.0-dev \
		cmake g++ g++-multilib libqt4-dev libqt4-dev libxi-dev libxtst-dev libX11-dev bc libsdl2-dev \
		gcc gcc-multilib nano
		
	else
	
		# exit out
		echo -e "Building on this architecture is not currently supported. Exiting."
		sleep 3s && exit
	
	fi

}

main()
{

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
	# Build PKG
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script
	wget "https://github.com/PCSX2/pcsx2/raw/master/debian-packager/create_built_tarball.sh"
	sh "create_built_tarball.sh"
	rm "create_built_tarball.sh"

	# unpack tarball
	tar -xf pcsx2*.tar.xz

	# actively get pkg ver from created tarball
	pkgver=$(find . -name *.orig.tar.xz | cut -c 18-41)

	# enter source dir
	cd pcsx2*

	# Add in debian folder
	cp -r debian-packager debian

	# Create basic changelog format
	cat <<-EOF> changelog.in
	$pkgname ($pkgver-$pkgrev) $dist_rel; urgency=low
	
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
	nano debian/changelog

 	# cleanup old files
 	rm -f changelog.in
 	rm -f debian/changelog.in

	############################
	# proceed to DEB BUILD
	############################

	echo -e "\n==> Building Debian package from source\n"
	sleep 2s

	# Build with dpkg-buildpackage

	#dpkg-buildpackage -us -uc -nc
	dpkg-buildpackage -rfakeroot -us -uc

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
	
	echo -e "Showing contents of: $build_dir: \n"
	ls "$build_dir"

	echo -e "\n==> Would you like to trim tar.gz, dsc files, and folders for uploading? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " trim_choice
	
	if [[ "$trim_choice" == "y" ]]; then
		
		# cut files so we just have our deb pkg
		sudo rm -f $git_dir/*.tar.gz
		sudo rm -f $git_dir/*.dsc
		sudo rm -f $git_dir/*.changes
		sudo rm -f $git_dir/*-dbg
		sudo rm -f $git_dir/*-dev
		sudo rm -f $git_dirs/*-compat

		# remove source directory that was made
		find $build_dir -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \;

	elif [[ "$trim_choice" == "n" ]]; then

		echo -e "File trim not requested"
	fi

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# cut files
		if [[ -d "$build_dir" ]]; then
			scp $build_dir/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
install_prereqs
main
