#!/bin/bash

# set -x

#
# Only intended for testing a local build
#

main ()
{

	echo -e "\n==> Prepping...\n"
	sleep 2s

	SCRIPTDIR="${PWD}"

	TMP_DIR="${HOME}/doomrl-local-build-test"
	mkdir -p "${TMP_DIR}"

	DOOM_RL_SRC="${TMP_DIR}/doomrl"
	VALKYRIE_SRC="${TMP_DIR}/fpcvalkyrie"
	VALKYRIE_ROOT="${VALKYRIE_SRC}/"
	OS="LINUX"
	DOOM_RL_CLIENT_VER="doomrl-linux-x64-0997"
	DOOM_RL_CLIENT_DL="https://drl.chaosforge.org/file_download/32/${DOOM_RL_CLIENT_VER}.tar.gz"
	DOOM_RL_CLIENT_DL_ALT="http://libregeek.org/Linux/game-files/doomrl/${DOOM_RL_CLIENT_VER}.tar"

	PKGS="build-essential fpc lua5.1 liblua5.1-0-dev fp-units-base curl"

	for PKG in ${PKGS};
	do

		echo -e "Installing: "${PKG}""

		if sudo apt-get install -y --force-yes ${PKG} &> /dev/null; then

			# PASS, but also show pkg version
			echo -e "Package: ${PKG} [OK]"
			dpkg -s ${PKG} | grep Version

		else

			# echo and exit if package install fails
			echo -e "Package: ${PKG} [FAILED] Exiting..."
			exit 1

		fi

	done

	# Enter tmp dir
	cd "${TMP_DIR}"

	echo -e "\n==> Fetching source code\n"
	sleep 1s

	# Get files 
	if [[ ! -d "${DOOM_RL_SRC}" ]]; then

		git clone https://github.com/ChaosForge/doomrl "${DOOM_RL_SRC}"

	else

		cd  "${DOOM_RL_SRC}"
		git clean -f
		git reset --hard

	fi

	if [[ ! -d "${VALKYRIE_SRC}" ]]; then

		git clone https://github.com/ChaosForge/fpcvalkyrie "${VALKYRIE_SRC}"

	else

		cd  "${VALKYRIE_SRC}"
		git clean -f
		git reset --hard

	fi

	# back out to main src dir
	cd  "${DOOM_RL_SRC}"

	# Download and extra required extras from doomrl download
	
	echo -e "\n==> Fetching assets\n"
	sleep 1s
	
	# TEMP ONLY
	# Download a mirror of asssets from libregeek
	# wget will refuse to download your game files via CLI, noting
	# "the certificate of drl.chaosforge.org hasn't got a known issuer" ...
	# The ALT archive just has the folders/files we need. I could not find music/sound/soundhq

#	wget "${DOOM_RL_CLIENT_DL}" -nc || (echo -e "\nERROR: Could not fetch assets!\n" && sleep 4s && exit 1)
	wget "${DOOM_RL_CLIENT_DL_ALT}" -nc || (echo -e "\nERROR: Could not fetch assets!\n" && sleep 4s && exit 1)
#	tar xzf "${DOOM_RL_CLIENT_VER}.tar.gz"
	tar xf "${DOOM_RL_CLIENT_VER}.tar"

	cp -r "${DOOM_RL_SRC}/mp3/"* "${DOOM_RL_SRC}/bin/mp3/"
	rm -rf "${DOOM_RL_SRC}/mp3"

#	cp -r "${DOOM_RL_CLIENT_VER}/mp3/"* "${DOOM_RL_SRC}/bin"
#	cp -r "${DOOM_RL_CLIENT_VER}/music/"* "${DOOM_RL_SRC}/bin"
#	cp -r "${DOOM_RL_CLIENT_VER}/sound/"* "${DOOM_RL_SRC}/bin"
#	cp -r "${DOOM_RL_CLIENT_VER}/soundhq/"* "${DOOM_RL_SRC}/bin"

	rm -r "${DOOM_RL_CLIENT_VER}"
	rm -f "${DOOM_RL_CLIENT_VER}.tar.*"

	echo -e "\n==> Configuring...\n"
	sleep 1s

	# create tmp path to see if that helps build error
	mkdir -p "${DOOM_RL_SRC}/tmp"

	# Add lua config and valkyrie root

	cat >> "${DOOM_RL_SRC}/config.lua" <<-EOF

	VALKYRIE_ROOT = "${VALKYRIE_ROOT}"
	OS = "${OS}"

	EOF

	echo -e "\n==> Building DOOMRL\n"
	sleep 2s

	# build
	# Add hq (high quality) or lq (low quality)
	lua makefile.lua hq

}

main 2>&1 | tee log.txt

echo "Log: "
cat log.txt | curl -F 'sprunge=<-' http://sprunge.us

rm -f log.txt
