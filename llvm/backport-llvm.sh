#!/bin/bash
#-------------------------------------------------------------------------------
# Author:       Michael DeGuzis
# Git:          https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:   backport-llvm.sh
# Script Ver:   0.4.1
# Description:  Attempts to backport the llvm package from Debian
#		code.
#
# NOTE:         Requires pbuilder!
#
# Usage:        ./backport-llvm.sh
# -------------------------------------------------------------------------------

echo -e "\n==> Seeting vars" && sleep 2s

# vars
temp_dir="$HOME/temp"
result_dir="${temp_dir}/result"
scriptdir="${PWD}"

# Set target LLVM version
PKG_VER="3.8"
DSC_VER="3.8_3.8.1-4"

# Enter working env
rm -rf ${temp_dir}
mkdir ${temp_dir}
cd ${temp_dir}

# Make result dir
mkdir -p ${result_dir}

DSC_URL="http://http.debian.net/debian/pool/main/l/llvm-toolchain-${PKG_VER}/llvm-toolchain-${DSC_VER}.dsc"

# get source
dget ${DSC_URL} -d

echo -e "==> Backporting package" && sleep 2s

# Do NOT pass "-E" to sudo below!
# For some reason, this particular build picks up environment information, and uses it 
# strangely with pbuilder

# Unset vars used in debian/rules (for safety)
# For one, BUILD_DIR is normally used by my build scripts.
unset BUILD_DIR
unset TARGET_BUILD
unset LLVM_VERSION

sudo -E DIST=brewmaster pbuilder --build --distribution brewmaster --buildresult result_dir \
--debbuildopts -sa --debbuildopts -nc llvm-toolchain-${DSC_VER}.dsc

# Show result (if good)

ls ${result_dir}
cd ${scriptdir}
