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

echo -e "\n==> Setting vars\n" && sleep 2s

#################
# vars
#################

# Set target LLVM version
POOL="pool/main/l"
PKG_NAME="llvm-toolchain"
PKG_VER="3.8"
FULL_VER="3.8_3.8.1"
DSC_VER="${FULL_VER}-4"

# Other vars
DIST_TARGET="brewmaster"

# dirs
TEMP_DIR="$HOME/temp"
RESULT_DIR="${TEMP_DIR}/result"
SCRIPTDIR="${PWD}"
SRC_DIR="${SCRIPTDIR}/SRC_DIR"

#################
# build
#################

# Enter working env
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}
mkdir -p ${SRC_DIR}
cd ${TEMP_DIR}

# Make result dir
mkdir -p ${RESULT_DIR}

DSC_URL="http://http.debian.net/debian/${POOL}/${PKG_NAME}-${PKG_VER}/${PKG_NAME}-${DSC_VER}.dsc"

# get source
# download only, don't unpack
dget ${DSC_URL} -d

echo -e "\n==> Patching debian/rules"
sleep 2s

# There is an issue with debian/rules and "BUILD_DIR", use our copy
tar -xf "${TEMP_DIR}/${PKG_NAME}-${DSC_VER}.debian.tar.xz"
cp -r "${SCRIPTDIR}/rules" "${TEMP_DIR}/debian/"

echo -e "\n==> Patching paths in debian/patches"
sleep 2s

# This is set to a long directory that was likely applied at the top level
# We are usign pbuilder and not applying patches before build

find "${TEMP_DIR}/debian/patches" -name "*.diff*" -print0 | xargs -0 \
sed -i "s|llvm-toolchain-snapshot_3.7~svn241915.orig/||"

#tar -cvf "${TEMP_DIR}/${PKG_NAME}-${DSC_VER}.debian.tar.xz" "debian"
#rm -rf "debian"

echo -e "\n==> Extracting original sources\n"
sleep 2s

# Extact the orig archives into one directory to use for original source
ORIG_TARBALL_VER="${PKG_NAME}-${FULL_VER}"

for filename in *.tar.bz2
do
  echo "Extracting ${filename}"
  tar xfj ${filename} -C "${SRC_DIR}"
done

# recreate as single tarball
echo -e "\n==> Creating original tarball" && sleep 2s
echo -e "    File: ${ORIG_TARBALL_VER}.orig.tar.gz"
tar -czf "${ORIG_TARBALL_VER}.orig.tar.gz" "$(basename ${SRC_DIR})"

# Add debian 
cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

# Remove cruft
rm -rf *.xz *.bz2 *.dsc

# ! TODO ! - once above debian fix verified, submit patch upstream (see: gmail thread)

echo -e "\n==> Backporting package\n" && sleep 2s

# Do NOT pass "-E" to sudo below!
# For some reason, this particular build picks up environment information, and uses it 
# strangely with pbuilder (need to confirm)

# Unset vars used in debian/rules (for safety)
# For one, BUILD_DIR is normally used by my build scripts.
unset BUILD_DIR
unset TARGET_BUILD
unset LLVM_VERSION

# For when upstream is fixed

#sudo -E DIST=${DIST_TARGET} pbuilder --build --distribution ${DIST_TARGET} --buildresult ${RESULT_DIR} \
#--debbuildopts -sa --debbuildopts -nc ${PKG_NAME}-${DSC_VER}.dsc

cd ${SRC_DIR}
BUILDER="pdebuild"
BUILDOPTS="--buildresult ${RESULT_DIR} --debbuildopts -sa --debbuildopts -nc"
DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

# Show result (if good)

ls ${RESULT_DIR}
cd ${SCRIPTDIR}
