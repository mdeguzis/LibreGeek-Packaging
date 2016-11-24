#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	build-darkmod.sh
# Script Ver:	0.6.1
# Description:	Attmpts to build a deb package from the laest "The Dark Mod"
#		release. This is more of a virtual package that deploys and updater
#		Which is run post-install.
#
# See:		https://github.com/ProfessorKaos64/tdm
#		http://wiki.darkmod.com/index.php?title=The_Dark_Mod_-_Compilation_Guide
#		http://wiki.darkmod.com/index.php?title=DarkRadiant_-_Compiling_in_Linux
#
# Usage:	./build-darkmod.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
SCRIPTDIR=$(pwd)
TIME_START=$(date +%s)
TIME_STAMP_START=(`date +"%T"`)


# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool TARGET(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/mnt/server_media_x/packaging/steamos-tools/incoming_testing"

else

	REPO_FOLDER="/mnt/server_media_x/packaging/steamos-tools/incoming"

fi
# upstream vars
#SRC_URL="https://github.com/ProfessorKaos64/tdm"
#TARGET="master"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH=""
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
export NO_LINTIAN="false"
export NO_PKG_TEST="false"
# required to run postinstall
USENETWORK="yes"
PKGNAME="darkmod"
PKGVER="2.0.4"
PKGREV="1"
PKGSUFFIX="git+bsos"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set BUILD_TMPs
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config bc debhelper gcc g++ \
	g++-4.9-multilib m4 zip libglew-dev libglew-dev:i386 libpng12-dev libpng12-dev:i386 \
	libjpeg62-dev libjpeg62-dev:i386 libc6-dev:i386 libxxf86vm-dev libxxf86vm-dev:i386 \
	libopenal-dev libopenal-dev:i386 libasound2-dev libasound2-dev:i386 libxext-dev \
	libxext-dev:i386 scons

}

main()
{

	# create BUILD_TMP
	if [[ -d "${BUILD_TMP}" ]]; then

		sudo rm -rf "${BUILD_TMP}"
		mkdir -p "${BUILD_TMP}"

	else

		mkdir -p "${BUILD_TMP}"

	fi

	# enter build dir
	cd "${BUILD_TMP}" || exit

	# install prereqs for build
	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and TARGET
	# NOTE! - If you wish to source versions or commits automatically into variables here,
	# 	  such as commits, of upstream tags, see docs/pkg-versioning.md

	echo -e "\n==> Obtaining upstream source code\n"

	######## Use a virtual package for now ########
	mkdir -p "${SRC_DIR}"
	cp -r "${SCRIPTDIR}/darkmod.png" "${SRC_DIR}"
	cp -r "${SCRIPTDIR}/darklauncher.sh" "${SRC_DIR}/darklauncher"
	cp -r "${SCRIPTDIR}/darkmod-updater.sh" "${SRC_DIR}"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# Trim .git folders
	find "${SRC_DIR}" -name "*.git" -type d -exec sudo rm -r {} \;

	# create source tarball
	cd "${BUILD_TMP}" || exit
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

	# Add debian folder for current virtual package implementation
	cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" -M --package \
		"${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Bump version of virtual package."
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		-M --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial upload"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	USENETWORK=$USENETWORK DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	#################################################
	# Cleanup
	#################################################

	# clean up dirs

	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$TIME_START) / 60 " | bc)

	# output finish
	echo -e "\nTime started: ${TIME_STAMP_START}"
	echo -e "Time started: ${time_stamp_end}"
	echo -e "Total Runtime (minutes): $runtime\n"


	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)

	# inform user of packages
	cat<<- EOF
	#################################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependency errors listed above.
	#################################################################

	EOF

	echo -e "Showing contents of: ${BUILD_TMP}: \n"
	ls "${BUILD_TMP}" | grep -E *${PKGVER}*

	# Ask to transfer files if debian binries are built
	# Exit out with log link to reivew if things fail.

	if [[ $(ls "${BUILD_TMP}" | grep -w "deb" | wc -l) -gt 0 ]]; then

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# uplaod local repo changelog
			cp "${SRC_DIR}/debian/changelog" "${SCRIPTDIR}/debian"

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	else

		# Output log file to sprunge (pastebin) for review
		echo -e "\n==OH NO!==\nIt appears the build has failed. See below log file:"
		cat ${BUILD_TMP}/${PKGNAME}*.build | curl -F 'sprunge=<-' http://sprunge.us

	fi

}

# start main
main

