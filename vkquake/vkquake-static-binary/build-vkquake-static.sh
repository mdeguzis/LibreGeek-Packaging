#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/mdeguzis/SteamOS-Tools
# Scipt name:	build-vkquake-static.sh
# Script Ver:	0.1.1
# Description:	Attmpts to build a deb package from the latest vkquake source
#		code. This is a static/bundled build.
#
# See:		https://github.com/Novum/vkQuake
#
# Usage:	./build-vkquake-static.sh
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

# upstream vars
#SRC_URL="https://github.com/mdeguzis/vkQuake"
SRC_URL="https://github.com/Novum/vkQuake"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER=""
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="false"
export NO_LINTIAN="false"
export NO_PKG_TEST="false"
PKGNAME="vkquake"
PKGREV="1"
PKGSUFFIX="linux_64"
epoch="1"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="mdeguzis"

# Set out targets if building a stable binary or git master

if [[ "$arg1" == "--testing" ]]; then

        REPO_FOLDER="/mnt/server_media_y/packaging/linux-binaries/testing"
        TARGET="master"
		PKGVER="${DATE_SHORT}git"

else

        TARGET="0.96"
        REPO_FOLDER="/mnt/server_media_y/packaging/linux-binaries/stable"
		# Source version from vkQuake/Quake/quakedef.h
		PKGVER="${TARGET}.0"

fi

# Need network for pbuilder to pull down ut4 zip
export NETWORK="yes"

# set build directories
export BUILD_TMP="${BUILD_TMP:=${HOME}/package-builds/build-${PKGNAME}-tmp}"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes dpkg-dev libflac-dev libmad0-dev libmikmod-dev \
	libopusfile-dev libsdl2-dev libvorbis-dev libvulkan-dev

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

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and get latest commit tag
	git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"
	cd "${SRC_DIR}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	# USENETWORK=$NETWORK DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	cd "${SRC_DIR}"

	make -C Quake clean
	make -C Quake release \
		DO_USERDIRS=1 \
		USE_SDL2=1 \
		USE_CODEC_FLAC=1 \
		USE_CODEC_OPUS=1 \
		USE_CODEC_MIKMOD=1 \
		USE_CODEC_UMX=1
	make -C Misc/vq_pak

	#################################################
	# Install process
	#################################################

	echo -e "\n==> Creating Linux binary package\n"
	sleep 3s

	# Move binary to root vkquake dir
	# check for built binary
	if [[ -f "${SRC_DIR}/Quake/vkquake" ]]; then
		echo "Successfully built vkQuake"
	else
		echo "Could not build vkQuake! Please ensure your GPU is Vulkan-capable." >&2
		sleep 5s
		exit 1
	fi

	# Add binary,libs, launcher, and readme

	cp -r ${SCRIPTDIR}/libs-all/* "${SRC_DIR}"
	cp "${SCRIPTDIR}/vkquake-launch.sh" "${SRC_DIR}"
	cp "${SCRIPTDIR}/vkquake.readme" "${SRC_DIR}"
	cp "${SRC_DIR}/Quake/vkquake" "${SRC_DIR}"

	# Get rid of all uncecessary files

	files="debian Misc Quake Shaders vkquake-launch Windows vkquake.png .git"

	for file in $files;
	do

		echo "Removing uneeded file: ${file}"
		rm -rf "${SRC_DIR}/${file}"

	done

	# Create tar archive

	cd "${BUILD_TMP}"
	tar -czvf "${PKGNAME}-${PKGVER}_${PKGSUFFIX}.tar.gz" $(basename ${SRC_DIR})

	#################################################
	# Cleanup
	#################################################

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
	ls "${BUILD_TMP}"

	# Ask to transfer files if debian binries are built
	# Exit out with log link to reivew if things fail.

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/libregeek-packaging/repo-filter.txt" \
			${BUILD_TMP}/${PKGNAME}*.gz ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

}

# start main
main
