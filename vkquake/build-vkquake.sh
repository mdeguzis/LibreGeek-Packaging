#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	build-vkquake.sh
# Script Ver:	0.1.1
# Description:	Attmpts to build a deb package from the latest vkquake source
#		code.
#
# See:		https://github.com/Novum/vkQuake
#
# Usage:	./build-vkquake.sh
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

	REPO_FOLDER="/mnt/server_media_y/packaging/ubuntu/incoming_testing"

else

	REPO_FOLDER="/mnt/server_media_y/packaging/ubuntu/incoming"

fi
# upstream vars
#SRC_URL="https://github.com/ProfessorKaos64/vkQuake"
SRC_URL="https://github.com/Novum/vkQuake"
TARGET="0.72"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa --debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="vkquake"
# Source version from vkQuake/Quake/quakedef.h
PKGVER="0.72"
PKGREV="1"
EPOCH="1"
DIST="${DIST:=yakkety}"
URGENCY="low"
UPLOADER="LibreGeek Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set build directories
export BUILD_TMP="${BUILD_TMP:-${HOME}/package-builds/build-${PKGNAME}-tmp}"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential vulkan-dev libsdl2-dev

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
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and get latest commit tag
	git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

        # Set PKGSUFFIX based on Ubuntu DIST
        case "${DIST}" in

                trusty)
                PKGVER="${PKGVER}~ubuntu14.04.5"
                ;;

                xenial)
                PKGVER="${PKGVER}~ubuntu16.04.1"
                ;;

                yakkety)
                PKGVER="${PKGVER}~ubuntu16.10"
                ;;

        esac

	# Add required files and artwork
	cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"
	cp "${SCRIPTDIR}/vkquake.png" "${SRC_DIR}"
	cp "${SRC_DIR}/LICENSE.txt" "${SRC_DIR}/debian/LICENSE"
	cp "${SCRIPTDIR}/vkquake-launch.sh" "${SRC_DIR}/vkquake-launch"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_TMP}" || exit
	tar -cvzf "${PKGNAME}_${PKGVER}.orig.tar.gz" $(basename ${SRC_DIR})

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	# "Update to the latest commit ${latest_commit}"
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" \
		"Upload for ${DIST}"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial build"
		nano "debian/changelog"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	USENETWORK=$NETWORK DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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

