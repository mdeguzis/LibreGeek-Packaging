#!/bin/bash

set -x

#
# Only intended for testing a local build
#

main ()
{

	TMP_DIR="${HOME}/doomrl-local-build-test"
	mkdir -p "${TMP_DIR}"

	DOOM_RL_SRC="${TMP_DIR}/doomrl"
	VALKYRIE_SRC="${TMP_DIR}/fpcvalkyrie"
	VALKYRIE_ROOT="${VALKYRIE_SRC}"
	OS="LINUX"

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

	# Get files 
	if [[ ! -d "${DOOM_RL_SRC}" ]]; then

		git clone https://github.com/ChaosForge/doomrl "${DOOM_RL_SRC}"

	else

		cd  "${DOOM_RL_SRC}"
		git pull

	fi

	if [[ ! -d "${VALKYRIE_SRC}" ]]; then

		git clone https://github.com/ChaosForge/fpcvalkyrie "${VALKYRIE_SRC}"

	else

		cd  "${VALKYRIE_SRC}"
		git pull

	fi

	# back out to main src dir
	cd  "${DOOM_RL_SRC}"

	# Clean files
	git clean -f

	# Add lua config and valkyrie root

	cat >> "${DOOM_RL_SRC}/bin/config.lua" <<-EOF

	VALKYRIE_ROOT = "${VALKYRIE_ROOT}"
	OS = "${OS}"

	EOF

	# build
	lua makefile.lua lq

}

main 2>&1 | tee log.txt

echo "Log: "
cat log.txt | curl -F 'sprunge=<-' http://sprunge.us

rm -f log.txt
