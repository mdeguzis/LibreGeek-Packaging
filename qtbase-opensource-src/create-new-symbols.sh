#!/bin/bash

rm -rf newsymbols
mkdir -p  newsymbols

# find lib packages with symbols
version="5.6.0"
pkgs=$(find . -type f -name "*.symbols" -printf "%f\n" | sed "s|.symbols||g")

for pkg in ${pkgs};
do

	dpkg -x ${pkg}_*.deb ${pkg}_5.6.0
	: > newsymbols/${pkg}.symbols
	dpkg-gensymbols -v5.6.0 -p${pkg} -P${pkg}_5.6.0 -Onewsymbols/${pkg}.symbols
	rm -rf ${pkg}5_5.6.0/

done
