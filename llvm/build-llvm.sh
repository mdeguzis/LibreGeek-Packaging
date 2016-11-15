#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-llvm-3.8.sh
# Script Ver:	1.0.0
# Description:	Attmpts to build a deb package from latest llvm-3.8
#
# Usage:	build-llvm-3.8.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

ARG1="$1"
SCRIPTDIR="${PWD}"
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

if [[ "$ARG1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming"

fi

BASEURL="http://http.debian.net/debian/pool/main/l"
PKGNAME="llvm-toolchain-snapshot"
LLVM_VER="4.0"
PKGREV="1"
PKGSUFFIX="~svn276280"
PKGREV="1"
LLVM_DSC_URL="${BASEURL}/${PKGNAME}/${PKGNAME}_${LLVM_VER}${PKGSUFFIX}-${PKGREV}~exp1.dsc"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa --debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"
#PKGNAME="llvm-toolchain-3.8"
PKGVER="${LLVM_VER}"
EPOCH="1"
DIST="brewmaster"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set BUILD_TMP
# 
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}${PKGSUFFIX}"

install_prereqs()
{

	echo -e "\n==> Installing $PKGNAME build dependencies...\n"
	sleep 2s

	sudo apt-get install -y --force-yes debhelper flex bison dejagnu tcl expect \
	cmake libtool chrpath sharutils libffi-dev python-dev libedit-dev \
	swig python-sphinx binutils-dev libjsoncpp-dev lcov help2man zlib1g-dev \
	texinfo python-six

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

	################################################
	# obtain sources
	#################################################

	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"
	sleep 2s

	dget "${LLVM_DSC_URL}"

	################################################
	# Build package
	#################################################

	# enter source dir if not already
	cd "${SRC_DIR}" || exit 1
	
#	echo -e "\n==> Updating changelog"
#	sleep 2s

	# update changelog with dch
#	if [[ -f "debian/changelog" ]]; then
#
#		dch -p --force-distribution -D "${DIST}" "Backport for SteamOS brewmaster"
#		nano "debian/changelog"
#
#	else
#
#		dch -p --create --force-distribution -v "${PKGVER}-${PKGREV}" --package "${PKGNAME}" \
#		-D "${DIST}" -u "${URGENCY}" "Initial upload"
#		nano "debian/changelog"
#
#	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	#  build
	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	#################################################
	# Cleanup
	#################################################

	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$TIME_START) / 60 " | bc)

	# output finish
	echo -e "\nTime started: ${TIME_STAMP_START}"
	echo -e "Time started: ${time_stamp_end}"
	echo -e "Total Runtime (minutes): $runtime\n"

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

