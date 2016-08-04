#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-llvm-3.8.sh
# Script Ver:	1.0.0
# Description:	Attempts to build a deb package from latest llvm-3.8
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
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

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
LLVM_VER="3.9"
PKGREV="1"
PKGSUFFIX="~svn274438-${PKGREV}"
LLVM_DSC_URL="${BASEURL}/${PKGNAME}/${PKGNAME}_${LLVM_VER}${PKGSUFFIX}.dsc"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="debuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"
#PKGNAME="llvm-toolchain-3.8"
PKGVER="${LLVM_VER}"
EPOCH="1"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_DIR
export BUILD_DIR="${HOME}/build-${PKGNAME}-temp"
SRC_DIR="${BUILD_DIR}/llvm-toolchain-3.8-3.8.1"

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

	################################################
	# obtain sources
	#################################################

	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"
	mkdir -p "${SRC_DIR}"
	dget "${LLVM_DSC_URL}"

	# ! TODO ! - once above debian fix verified, submit patch upstream (see: gmail thread)

	################################################
	# Prepare sources
	#################################################

	echo -e "\n==> Patching"
	sleep 2s

	# add patched rules file and series
	cp -r "${SCRIPTDIR}/patches/series" "${SRC_DIR}/debian/patches/"
	cp -r "${SCRIPTDIR}/patches/fix-rules-build-dir" "${SRC_DIR}/debian/patches/"

	# Patch
	cd "${SRC_DIR}"
	quilt push fix-rules-build-dir 

	################################################
	# Build package
	#################################################

	# enter source dir if not already
	cd "${SRC_DIR}"
	
	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -D "${DIST}" "Backport for SteamOS brewmaster"
	#	nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}-${PKGREV}" --package "${PKGNAME}" \
		-D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"

	fi

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
	cat<<-EOF

	###############################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependcy errors listed above.
	###############################################################

	Showing contents of: ${BUILD_DIR}

	EOF

	ls "${BUILD_DIR}"

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_DIR}" ]]; then
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_DIR}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${GIT_DIR}/debian/changelog" "${SCRIPTDIR}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
