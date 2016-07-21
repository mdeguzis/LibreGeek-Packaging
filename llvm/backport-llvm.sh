#!/bin/bash

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

# get source
dget ${DSC_URL} -d

DSC_URL="http://http.debian.net/debian/pool/main/l/llvm-toolchain-${PKG_VER}/llvm-toolchain-${VER}.dsc"

sudo -E DIST=brewmaster pbuilder --build --distribution brewmaster --buildresult result_dir \
--debbuildopts -sa --debbuildopts -nc llvm-toolchain-${VER}.dsc

# Show result (if good)

ls ${result_dir}
cd ${scriptdir}
