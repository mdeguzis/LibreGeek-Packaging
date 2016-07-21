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

echo -e "\n==> Setting vars" && sleep 2s

#################
# vars
#################

# Set target LLVM version
POOL="pool/main/l"
PKG_NAME="llvm-toolchain"
PKG_VER="3.8"
DSC_VER="3.8_3.8.1-4"

# Other vars
DIST_TARGET="brewmaster"

# dirs
TEMP_DIR="$HOME/temp"
RESULT_DIR="${TEMP_DIR}/result"
SCRIPTDIR="${PWD}"

#################
# build
#################

# Enter working env
rm -rf ${TEMP_DIR}
mkdir ${TEMP_DIR}
cd ${TEMP_DIR}

# Make result dir
mkdir -p ${RESULT_DIR}

DSC_URL="http://http.debian.net/debian/${POOL}/${PKGNAME}-${PKG_VER}/${PKG_NAME}-${DSC_VER}.dsc"

# get source
# download only, don't unpack
dget ${DSC_URL} -d

echo -e "==> Patching debian/rules"
sleep 2s

# There is an issue with debian/rules and "BUILD_DIR", use our copy
tar -xvf "${TEMP_DIR}/${PKG_NAME}-${DSC_VER}.debian.tar.xz"
cp -r "${SCRIPTDIR}/rules" "${TEMP_DIR}/debian/"
tar -cvf "${TEMP_DIR}/${PKG_NAME}-${DSC_VER}.debian.tar.xz" "debian"
rm -rf "debian"

# ! TODO ! - once above debian fix verified, submit patch upstream (see: gmail thread)

echo -e "==> Finished patching debian/rules"
sleep 2s

echo -e "==> Backporting package" && sleep 2s

# Do NOT pass "-E" to sudo below!
# For some reason, this particular build picks up environment information, and uses it 
# strangely with pbuilder (need to confirm)

# Unset vars used in debian/rules (for safety)
# For one, BUILD_DIR is normally used by my build scripts.
unset BUILD_DIR
unset TARGET_BUILD
unset LLVM_VERSION

sudo -E DIST=${DIST_TARGET} pbuilder --build --distribution ${DIST_TARGET} --buildresult ${RESULT_DIR} \
--debbuildopts -sa --debbuildopts -nc ${PKG_NAME}-${DSC_VER}.dsc

# Show result (if good)

ls ${result_dir}
cd ${SCRIPTDIR}
