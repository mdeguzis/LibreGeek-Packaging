#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-gpmdp.sh
# Script Ver:	0.1.1
# Description:	Builds simple pacakge for using google-play-music-desktop-player based of of master upstream
#		git source

# See:		https://github.com/MarshallOfSound/Google-Play-Music-Desktop-Player-UNOFFICIAL-
#
# Usage:	./build-gpmdp.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)


# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool target(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

# upstream vars
git_url="https://github.com/MarshallOfSound/Google-Play-Music-Desktop-Player-UNOFFICIAL-"
rel_target="3.0.0"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="debuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="google-play-music-desktop-player"
pkgver="3.0.0"
upstream_rev="1"
pkgrev="1"
pkgsuffix="bsos${pkgrev}"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_DIR
export BUILD_DIR="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${BUILD_DIR}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	# Additional suggested packages added per: https://wiki.debian.org/Python/LibraryStyleGuide
	sudo apt-get install -y --force-yes build-essential bc debhelper dh-buildinfo nodejs npm

}

main()
{

	# create BUILD_DIR
	if [[ -d "${BUILD_DIR}" ]]; then

		sudo rm -rf "${BUILD_DIR}"
		mkdir -p "${BUILD_DIR}"

	else

		mkdir -p "${BUILD_DIR}"

	fi

	# enter build dir
	cd "${BUILD_DIR}" || exit

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi


	echo -e "\n==> Obtaining upstream source code\n"

	# clone and checkout desired commit
	git clone -b "${rel_target}" "${git_url}" "${git_dir}"

	# Enter git dir to build
	cd "${git_dir}"

	# Since this uses npm and has a lot of depedencies that woudl take a long
	# time to convert to Debian packages, build manually for now.

	echo -e "\n==> Building project\n"
        sleep 2s

	npm install
        npm run build
        npm start

	echo -e "\n==> Creating Debian package\n"
	sleep 2s

        npm run make:deb

	#################################################
	# Cleanup
	#################################################

	# clean up dirs

	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)

	# output finish
	echo -e "\nTime started: ${time_stamp_start}"
	echo -e "Time started: ${time_stamp_end}"
	echo -e "Total Runtime (minutes): $runtime\n"

	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"

	echo -e "Showing contents of: ${BUILD_DIR}: \n"
	ls "${BUILD_DIR}" | grep ${pkgver}

	if [[ "$autobuild" != "yes" ]]; then

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Transfer files: [y/n] " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# transfer packages
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_DIR}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}


		elif [[ "$transfer_chice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi
	fi

}

# start main
main
