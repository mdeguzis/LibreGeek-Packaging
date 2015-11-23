#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	kodi-build-all.sh
# Script Ver:	0.1.1
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
	# These packages will be removed at the end of this script
	# In the the future, this behavior will be replaced by pbuilder/chroot.
	
	# NOTE: This package script list is not yet complete
	# There are move PPA packages to replace.
	package="libcec kodi-platform platform afpfs-ng"
	
	if ./build-${package}.sh; then
	
		echo -e "Package ${package} build sucessfully"
		sleep 3s
	
	else
	
		echo -e "Package ${package} build FAILED. Please review log.txt"
		sleep 3s
	
	done
	
	
	# Install packages to clean build environment
	sudo gdebi $build_dir/libcec*.deb
	sudo gdebi $build_dir/libkodiplatform-dev*.deb
	sudo gdebi $build_dir/platform-dev*.deb
	sudo gdebi $build_dir/afpfs-ng*.deb
	
	###########################################################
	# build Main Kodi package and pvr addons
	###########################################################
	
	package="kodi pvr-argustv pvr-demo pvr-dvblink pvr-dvbviewer pvr-filmon pvr-hts \
	pvr-iptvsimple pvr-mediaportal-tvserver pvr-mythtv pvr-nextpvr pvr-njoy pvr-pctv \
	pvr-stalker pvr-vbox pvr-vdr-vnsi pvr-vuplus pvr-wmc"
	
	for dep in ${package}; do
	
	if ./build-${package}.sh; then
	
		echo -e "Package ${package} build sucessfully"
		sleep 3s
	
	else
	
		echo -e "Package ${package} build FAILED. Please review log.txt"
		sleep 3s
	
	done

}

# start functions
build_all | tee $build_dir/build-log.txt
