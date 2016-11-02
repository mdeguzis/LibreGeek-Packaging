#!/bin/bash

# Builds gcc into a temporary directory
# See: https://gcc.gnu.org/wiki/InstallingGCC

#################################
# Vars
#################################
TMP_DIR="/opt/build-gcc"
GCC_PREFIX="$HOME"

GCC_RELEASE_URL="http://www.netgull.com/gcc/releases"
GCC_VER="5.4.0"

#################################
# Setup
#################################

# Get required packages
# Setup just for Debian/SteamoS/Ubuntu right now

sudo apt-get install -y gcc-4.9-plugin-dev

sudo mkdir -p "${TMP_DIR}"
sudo mkdir -p "${GCC_PREFIX}"

#################################
# Build
#################################

wget ${GCC_RELEASE_URL}/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz
tar xzf gcc-${GCC_VER}.tar.gz
cd gcc-${GCC_VER}
./contrib/download_prerequisites
cd ..
mkdir objdir
cd objdir
# We need to disable shared libs, otherwise libiberty and others will fail when invoking make
$PWD/../gcc-${GCC_VER}/configure \
	--disable-shared \
	--prefix=${GCC_PREFIX}/gcc--${GCC_VER} \
	--enable-languages=c,c++,fortran,go
make
sudo make install
