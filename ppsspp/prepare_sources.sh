#!/bin/bash
# -------------------------------------------------------------------------------
# Author: 	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	prepare_sources.sh
# Script Ver:	1.0.0
# Description:	Creates a diff file off ppsspp git master and the PPA latest git
#               package for Ubuntu 15.10. For whatever reason, many file
#               differences exist between the two.
#
# Usage:	./prepare_sources.sh
# -------------------------------------------------------------------------------

# examples
# diff -r dir1 dir2 | grep dir1 | awk '{print $4}' > difference1.txt
# diff -r dir1 dir2 shows which files are only in dir1 and those only in dir2
# diff -r dir1 dir2 | grep dir1 shows which files are only in dir1

echo -e "\n==> Downloading sources\n"
sleep 2s

# Download sources
git clone https://github.com/hrydgard/ppsspp git_source
wget https://launchpad.net/~ppsspp/+archive/ubuntu/testing/+files/ppsspp_*ubuntu15.10.1.tar.xz -C ppa_source

# run diff to file

echo -e "\n==> Creating diff as $pwd/source_differences.txt\n"
sleep 2s

diff -r git_source ppa_source | grep git_source | awk '{print $4}' > source_differences.txt

# Rsync folder missing files
# rsync -options --otherOptions sourceDir targetDir
# Only missing files -> 

echo -e "\n==> Copying missing files into git dir"

rsync -avz ppa_source git_dir

echo -e "\n==> Removing PPA dir"

# remove
rm -rf ppsspp_*ubuntu15.10.1*

# rename folder for package build
mv git_dir ppsspp
