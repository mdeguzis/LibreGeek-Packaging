#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-afpfs-ng.sh
# Script Ver:	0.5.5
# Description:	Attempts to build a deb package from afpfs-ng git source
#
# See:		https://github.com/simonvetter/afpfs-ng
# Usage:	build-afpfs-ng.sh
# -------------------------------------------------------------------------------

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)
# reset source command for while loop
src_cmd=""

# upstream URL
git_url="https://github.com/simonvetter/afpfs-ng"

# package vars
pkgname="afpfs-ng"
pkgrel="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"
provides="afpfs-ng, afpfs-ng-utils, libafpclient-dev, libafpclient0"
pkggroup="utils"
requires=""
replaces="afpfs-ng, afpfs-ng-utils, libafpclient-dev, libafpclient0"

# build dirs
build_dir="/home/desktop/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

install_prereqs()
{

	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config checkinstall bc \
	debhelper fuse ncurses-dev libreadline-dev libfuse-dev libgcrypt20
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
	# Clone upstream source
	#################################################

	echo -e "\n==> Fetching $pkgname upstream source\n"
	sleep 2s

	git clone "$git_url" "$git_dir"
	cd "$git_dir"

	#################################################
	# Build afpfs-ng (uses standard make)
	#################################################
  
  	echo -e "\n==> Creating $pkgname build files\n"
	sleep 2s

	./configure && make && echo 'done!'

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building $pkgname Debian package from source\n"
	sleep 2s

	sudo checkinstall --pkgname="$pkgname" --fstrans="no" --backup="no" \
	--pkgversion="$(date +%Y%m%d)+git" --pkgrelease="$pkgrel" \
	--deldoc="yes" --maintainer="$maintainer" --provides="$provides" --replaces="$replaces" \
	--pkggroup="$pkggroup" --requires="$requires" --exclude="/home"

	#################################################
	# Post install configuration
	#################################################
	
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
	
	# If "build_all" is requested, skip user interaction
	
	if [[ "$build_all" == "yes" ]]; then
	
		echo -e "\n==INFO==\nAuto-build requested"
		mv ${git_dir}/build/*.deb "$auto_build_dir"
		sleep 2s
		
	else
		
		# inform user of packages
		echo -e "\n############################################################"
		echo -e "If package was built without errors you will see it below."
		echo -e "If you don't, please check build dependcy errors listed above."
		echo -e "############################################################\n"
		
		echo -e "Showing contents of: ${git_dir}/build: \n"
		ls "${git_dir}/build" | grep -E *.deb
	
		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -ep "Choice: " transfer_choice
		
		if [[ "$transfer_choice" == "y" ]]; then
		
			# cut files
			if [[ -d "${git_dir}/build" ]]; then
				scp ${git_dir}/build/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming
	
			fi
			
		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	fi
	
}

# start main
install_prereqs
main
