#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	kodi-build-all.sh
# Script Ver:	0.3.1
# Description:	Attempts to build all kodi packages and addons into a temporary
#               folder under $HOME/kodi-all-tmp/
#               This script passes "build_all=yes" to each script.
#
# See:		n/a
# Usage:	kodi-build-all.sh
# -------------------------------------------------------------------------------

# Set vars
auto_build_dir="$HOME/kodi-all-tmp"
build_all="yes"

install_prereqs()
{

	# Install basic build packages
	sudo apt-get install -y --force-yes autoconf automake autopoint autotools-dev bc ccache cmake \
	build-essential

	# create and enter build_dir
	if [[ -d "$auto_build_dir" ]]; then

		sudo rm -rf "$auto_build_dir"
		mkdir -p "$auto_build_dir"

	else

		mkdir -p "$auto_build_dir"

	fi

}

build_all()
{
	# Install prereqs
	install_prereqs

	###########################################################
	# build Kodi prerequisite packages 
	###########################################################
	# Install them for the main builds
	# In the the future, this behavior will be replaced by pbuilder/chroot.

	# NOTE: This package script list is not yet complete
	# There are move PPA packages to replace.
	pkgs="libcec kodi-platform platform afpfs-ng taglib"


	for pkg in ${pkg};
	do

		cat <<-EOF
		-------------------------------------
		Building ${pkg}
		-------------------------------------
		
		EOF
		sleep 3s
		
		if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} build sucessfully"
			sleep 3s

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s
			
		fi

	done

	# Install packages to clean build environment
	sudo gdebi $build_dir/libcec*.deb
	sudo gdebi $build_dir/libkodiplatform-dev*.deb
	sudo gdebi $build_dir/platform-dev*.deb
	sudo gdebi $build_dir/afpfs-ng*.deb
	sudo gdebi $build_dir/taglib*.deb

	###########################################################
	# build Main Kodi package and pvr addons
	###########################################################

	pkgs="kodi pvr-argustv pvr-demo pvr-dvblink pvr-dvbviewer pvr-filmon pvr-hts \
	pvr-iptvsimple pvr-mediaportal-tvserver pvr-mythtv pvr-nextpvr pvr-njoy pvr-pctv \
	pvr-stalker pvr-vbox pvr-vdr-vnsi pvr-vuplus pvr-wmc kodi-audioencoder-lame \
	kodi-audioencoder-flac"

	for pkg in ${pkgs};
	do
	
		cat <<-EOF
		-------------------------------------
		Building ${pkg}
		-------------------------------------
		
		EOF
		sleep 3s

		if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} build sucessfully"
			sleep 3s

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s
			
		fi

	done

	###########################################################
	# Summary
	###########################################################

	# inform user of packages
	echo -e "\n#######################################################################"
	echo -e "If all kodi packages were built without errors you will see them below."
	echo -e "If you don't, please check the $build_dir/build-log.txt log."
	echo -e "#########################################################################\n"

	echo -e "Showing contents of: $auto_build_dir: \n"
	ls "${auto_build_dir}" | grep -E *.deb

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# cut files
		if [[ -d "${auto_build_dir}/" ]]; then
			scp ${auto_build_dir}/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start functions
build_all | tee $auto_build_dir/build-log.txt
