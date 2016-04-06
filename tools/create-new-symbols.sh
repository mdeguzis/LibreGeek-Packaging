#!/bin/bash

rm -rf newsymbols
mkdir -p  newsymbols

# find lib packages with symbols
version="5.6.0"
pkgs=$(find . -type f -name "*.symbols" -printf "%f\n" | sed "s|.symbols||g")

for pkg in ${pkgs};
do

	dpkg -x ${pkg}_*.deb ${pkg}_${version}
	: > newsymbols/${pkg}.symbols
	dpkg-gensymbols -v${version} -p${pkg} -P${pkg}_${version} -Onewsymbols/${pkg}.symbols
	rm -rf ${pkg}_${version}/

done
