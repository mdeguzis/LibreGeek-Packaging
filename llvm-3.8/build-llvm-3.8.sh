#!/bin/bash

scriptdir=${PWD}

# temp dir
mkdir -p $HOME/tmp
cd $HOME/tmp

# get source
dget llvm-toolchain-3.8_3.8-2.dsc

# Remove debian.tar.xz
rm -f llvm-toolchain-3.8_3.8-2.debian.tar.xz

# Copy ours
cp "${scriptdir}/debian" .

# tar it up
tar -cvf llvm-toolchain-3.8_3.8-2.debian.tar.xz debian

# buikd attempt
rm -rf result_dir && mkdir result_dir && sudo -E DIST=brewmaster \
pbuilder --build --distribution brewmaster --buildresult result_dir --debbuildopts -sa \
--debbuildopts -nc llvm-toolchain-3.8_3.8-2.dsc
