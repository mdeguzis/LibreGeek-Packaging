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

# remove previous dirs if left behind
rm -rf git_source ppa_source index.html* ppsspp*

# Get PPA latest version for 15.10
target="15.10"
URL="https://launchpad.net/~ppsspp/+archive/ubuntu/testing/"

#######################
# Perform evaluation
######################

wget --quiet -A --no-parent 'index.html' ${URL}
latest_version=$(cat index.html | grep -A 4 'ppsspp$' | grep ${target} | awk '{print $1}')
rm -f index.html
echo -e "Working with version: $latest_version"

#######################
# Download sources
#######################

# git
git clone --recursive https://github.com/hrydgard/ppsspp git_source

# PPA
mkdir -p ppa_source
wget --quiet https://launchpad.net/~ppsspp/+archive/ubuntu/testing/+files/ppsspp_${latest_version}.tar.xz
tar -xf ppsspp_${latest_version}.tar.xz
mv ppsspp* ppa_source
rm -rf ppsspp_${latest_version}.tar.xz

#######################
# run diff to file
#######################

echo -e "\n==> Creating diff as $PWD/source_differences.txt"
sleep 2s

diff -r git_source ppa_source | grep git_source | awk '{print $4}' > source_differences.txt

# Rsync folder missing files
# rsync -options --otherOptions sourceDir targetDir
# Only missing files ->

echo -e "\n==> Copying missing files into git dir"
sleep 2s

# We want to keep some modified files from the PPA source code, but sync
# the rest missing from the git master folder
rsync -avz --exclude-from "$scriptdir/exclude-list.txt" ppa_source git_dir

echo -e "\n==> Transferring to build dir"

# rename folder for package build
mv git_dir ppsspp

# relocate
mv git_source/* "$git_dir/"

echo -e "\n==> Removing uneeded dirs"

# remove
rm -rf git_source ppa_source ppssp
