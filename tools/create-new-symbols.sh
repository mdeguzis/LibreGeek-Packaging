#!/bin/bash

# About
# Processing all sonames in an extracted folder can follow a process such as what 
# Debian documentation describes. To use the below, move any .symbols install files 
# out of the debian/ directory, build the package, then move them back for the next step.
# It is advised to use a temporry directory containing the old symbols files and the build debs.

# Usage: ./create-new-symobols <DIRECTORY> <PACKGE_VERSION>:

# find lib packages with symbols
DIRECTORY="$1"
VERSION="$2"
SCRIPTDIR="${PWD}"

# Setup directories
cd ${DIRECTORY} || exit 1
rm -rf newsymbols
mkdir -p  newsymbols

# symbols and debs required
if [[ $(find ${PWD} -name "*.deb") == "" ]]; then
	echo "ERROR: Please ensure debian binaries are in folder ${DIRECTORY}"
	sleep 5s
	exit 1
fi

if [[ $(find ${PWD} -name "*.symbols") == "" ]]; then
	echo "ERROR: Please ensure old package symbols are in folder ${DIRECTORY}"
	sleep 5s
	exit 1
fi

# Process list
PKGS=$(find . -type f -name "*.symbols" -printf "%f\n" | sed "s|.symbols||g")

for PKG in ${PKGS};
do

	dpkg -x ${PKG}_*.deb ${PKG}_${VERSION}
	: > newsymbols/${PKG}.symbols
	dpkg-gensymbols -v${VERSION} -p${PKG} -P${PKG}_${VERSION} -Onewsymbols/${PKG}.symbols
	rm -rf ${PKG}_${VERSION}/

done

cd "${SCRIPTDIR}"
