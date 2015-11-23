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
build_dir="$HOME/kodi-all-tmp"
build_all="yes"

# create and enter build_dir
if [[ -d "$build_dir" ]]; then

	sudo rm -rf "$build_dir"
	mkdir -p "$build_dir"
	
else

	mkdir -p "$build_dir"
	
fi

###########################################################
# build Kodi prerequisite packages 
###########################################################
# Install them for the main builds
# These packages will be removed at the end of this script
# In the the future, this behavior will be replaced by pbuilder/chroot.

# NOTE: This package script list is not yet complete
# There are move PPA packages to replace.
package="libcec kodi-platform platform"

for dep in ${package}; do

  if ./build-${package}.sh; then
  echo -e "Package ${package} build sucessfully"
  sleep 3s
  
done



