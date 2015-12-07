#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-openpht.sh
# Script Ver:	1.0.3
# Description:	Attempts to builad a deb package from latest plexhometheater
#		github release
#
# See:		https://github.com/RasPlex/OpenPHT
#
# Usage:	build-openpht.sh
#
#-------------------------------------------------------------------------------

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

# upstream vars
#git_url="https://github.com/plexinc/plex-home-theater-public"
#git_url="https://github.com/ProfessorKaos64/plex-home-theater-public"
git_url="https://github.com/RasPlex/OpenPHT"
#branch="pht-frodo"
branch="openpht-1.5"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="openpht"
pkgver="${date_short}+git+bsos"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dir
build_dir="$HOME/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc \
	cmake debhelper cdbs unzip libboost-dev zip libgl1-mesa-dev libglu1-mesa-dev \
	libglew-dev libmad0-dev libjpeg-dev libsamplerate-dev libogg-dev libvorbis-dev \
	libfreetype6-dev libfontconfig-dev libbz2-dev libfribidi-dev libsqlite3-dev \
	libasound2-dev libpng12-dev libpcre3-dev liblzo2-dev libcdio-dev libsdl-dev \
	libsdl-image1.2-dev libsdl-mixer1.2-dev libenca-dev libjasper-dev libxt-dev \
	libxmu-dev libcurl4-gnutls-dev libdbus-1-dev libpulse-dev libavahi-common-dev \
	libavahi-client-dev libxrandr-dev libmpeg2-4-dev libass-dev libflac++-dev \
	libflac-dev zlib1g-dev libsmbclient-dev libiso9660-dev libssl-dev libvdpau-dev \
	libmicrohttpd-dev libmodplug-dev librtmp-dev curl libyajl-dev libboost-thread-dev \
	libboost-system-dev libplist-dev libcec-dev libudev-dev libshairport-dev libtiff5-dev \
	libtinyxml-dev libmp3lame-dev libva-dev yasm

}

main()
{

	# create build_dir
	if [[ -d "$build_dir" ]]; then

		sudo rm -rf "$build_dir"
		mkdir -p "$build_dir"

	else

		mkdir -p "$build_dir"

	fi

	# enter build dir
	cd "$build_dir" || exit

	# install prereqs for build
	install_prereqs

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone -b "$branch" "$git_url" "$git_dir"

        # copy in debian folder and other files
        cp -r "$scriptdir/$pkgname/debian" "${git_dir}"
        cp -r "$scriptdir/$pkgname/openpht_460x215.png" "${git_dir}/"
        cp -r "$scriptdir/$pkgname/openpht.desktop" "${git_dir}/"
        cp -r "$scriptdir/$pkgname/openpht.sh" "${git_dir}/"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${pkgname}" 

	# enter source dir
	cd "${pkgname}"

	# Create basic changelog format
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname ($pkgver) $dist_rel; urgency=low

	  * Packaged deb for SteamOS-Tools
	  * See: packages.libregeek.org
	  * Upstream authors and source: $git_url
	  * This pacakge is made using the OpenPHT fork of PHT

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

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	dpkg-buildpackage -rfakeroot -us -uc

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
		cd "$scriptdir" || exit
	else
		cd "$HOME" || exit
	fi
	
	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	echo -e "Showing contents of: ${build_dir}: \n"
	ls ${build_dir}| grep -E *.deb

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice
	
	if [[ "$transfer_choice" == "y" ]]; then
	
		# cut files
		if [[ -d "${build_dir}" ]]; then
			scp ${build_dir}/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

		fi
		
	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
