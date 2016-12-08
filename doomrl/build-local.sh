#!/bin/bash

#
# Only intended for testing a local build
#

TMP_DIR="${HOME}/doomrl-local-build-test"
mkdir -p "${TMP_DIR}"

DOOM_RL_SRC="${TMP_DIR}/doomrl"
VALKYRIE_SRC="${TMP_DIR}/fpcvalkyrie"

# deps
sudo apt-get install -y --force-yes build-essential fpc lua5.1 liblua5.1-0-dev fp-units-base

# Enter tmp dir
cd "${TMP_DIR}"

# Get files 
if [[ ! -d "${DOOM_RL_SRC}" ]]; then

	git clone https://github.com/ChaosForge/doomrl "${DOOM_RL_SRC}"

else

	cd  "${DOOM_RL_SRC}"
	git pull

fi

if [[ ! -d "${VALKYRIE_SRC" ]]; then

	git clone https://github.com/ChaosForge/fpcvalkyrie "${VALKYRIE_SRC}"
	
else

	cd  "${VALKYRIE_SRC}"
	git pull

fi

# back out to main src dir
cd  "${DOOM_RL_SRC}"

# Clean files
git clean -f

# build
lua makefile.lua lq
