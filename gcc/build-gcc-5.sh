#!/bin/bash
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Goal: build gcc piece-by-piece to allow use via /opt
# NO LONGER USED, NOT THE CORRECT WAY TO GO ABOUT THIS
# ONLY KEPT HERE FOR ANECDOTAL REFERENCE!!!
# PROPER METHOD: http://gcc.gnu.org/wiki/InstallingGCC
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#########################################################
# Notes section
#
# http://stackoverflow.com/questions/9450394/how-to-install-gcc-piece-by-piece-with-gmp-mpfr-mpc-elf-without-shared-libra
#
########################################################

#################################
# Vars
#################################
INFRASTRUCTURE_DIR="/opt/downloads"
GCC_PREFIX="/opt/gcc"
GCC_SCRATCH_DIR="/opt/gcc-scratch"
ARCH="amd64"

GCC_INFRASTRUCTURE_URL="ftp://gcc.gnu.org/pub/gcc/infrastructure"
ELF_URL="http://www.mr511.de/software"
GCC_RELEASE_URL="http://www.netgull.com/gcc/releases"

GMP_VER="6.1.0"
MPFR_VER="3.1.4"
ELF_VER="0.8.13"
GCC_VER="5.4.0"

#################################
# Setup
#################################
sudo mkdir -p "${INFRASTRUCTURE_DIR}"
sudo mkdir -p "${PREFIX}"
sudo mkdir -p "${GCC_SCRATCH_DIR}"

#################################
# Build infrastructure
#################################

cd "${INFRASTRUCTURE_DIR}"

# GMP
# GMP is the GNU Multiple Precision Arithmetic Library.

wget ${GCC_INFRASTRUCTURE_URL}/gmp-${GMP_VER}.tar.bz2
bunzip2 ${GMP_VER}.tar.bz2
tar xvf ${GMP_VER}.tar
cd gmp-${GMP_VER}
./configure --disable-shared --enable-static --prefix=${GCC_PREFIX}
make && make check && sudo make install

# MPFR
# MPFR is the GNU Multiple-precision floating-point rounding library. It depends on GMP.

wget ${GCC_INFRASTRUCTURE_URL}/mpfr-${MPFR_VER}.tar.bz2
bunzip2 mpfr-${MPFR_VER}.tar.bz2
tar xvf mpfr-${MPFR_VER}2.tar
cd mpfr-${MPFR_VER}
./configure --disable-shared --enable-static --prefix=/tmp/gcc --with-gmp=${GCC_PREFIX}
make && make check && sudo make install

# ELF
# ELF stands for Executable and Linkable Format. 
# This library provides architecture-independent size and endian support.

wget ${ELF_URL}/libelf-${ELF_VER}.tar.gz
tar zxvf libelf-${ELF_VER}.tar.gz
cd libelf-${ELF_VER}
./configure --disable-shared --enable-static --prefix=${GCC_PREFIX}
make && make check && sudo make install

#################################
# Build gcc
#################################

cd ${GCC_SCRATCH_DIR}

# GCC
# GCC is the GNU Compiler Collection. It depends on GMP, MPFR, MPC, and ELF.

wget ${GCC_RELEASE_URL}/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz
tar zxvf gcc-${GCC_VER}.tar.gz

./configure \
	--disable-shared \
	--disable-bootstrap \
	--disable-libstdcxx-pch \
	--enable-languages=all \
	--enable-libgomp \
	--enable-lto \
	--enable-threads=posix \
	--enable-tls \
	--with-gmp=/tmp/gcc \
	--with-mpfr=/tmp/gcc \
	--with-mpc=/tmp/gcc \
	--with-libelf=/tmp/gcc \
 	--with-fpmath=sse \
make && sudo make install
