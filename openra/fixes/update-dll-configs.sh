#!/bin/bash
# Updates dll config files for patching during build.
# dh_clideps does not understand the "dllentry" syntax.
# Take the config files from the Ubuntu package which uses the "target" syntax.

SCRIPTDIR="${PWD}"

VERSION="20160508"
RELEASE="release-${VERSION}/openra_release.${VERSION}_all.deb"

mkdir "temp_extract"
cd ${temp_extract}

echo -e "\n==> Fetching release pacakge\n"
sleep 2s

wget "https://github.com/OpenRA/OpenRA/releases/download/${RELEASE}" \
-w -nc --show-progress

echo -e "\n==> Extracting\n"
sleep 2s

ar -x *.deb
tar -xf data.tar.gz
cp usr/lib/openra/SDL2-CS.dll "${PWD}"
cp usr/lib/openra/SDL2-CS.dll.config "${PWD}"

# cleanup

cd "${SCRIPTDIR}"
rm -rf temp_extract
