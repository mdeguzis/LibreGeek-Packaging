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

	REPO_FOLDER="/home/mikeyd/packaging/static-builds/testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/static-builds/stable"

fi
# upstream vars
#GIT_URL="https://github.com/ProfessorKaos64/vkQuake"
GIT_URL="https://github.com/Novum/vkQuake"
branch="master"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="vkquake"
# Source version from vkQuake/Quake/quakedef.h
PKGVER="0.50"
PKGREV="1"
epoch="1"
PKGSUFFIX="${DATE_SHORT}git+bsos"
DIST="brewmaster"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# Need network for pbuilder to pull down ut4 zip
export NETWORK="yes"

# set build directories
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_TMP}/${SRCDIR}"

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
	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and get latest commit tag
	git clone -b "${branch}" "${GIT_URL}" "${GIT_DIR}"
	cd "${GIT_DIR}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")

	# Add required files and artwork
	cp -r "${SCRIPTDIR}/debian" "${GIT_DIR}"
	cp "${SCRIPTDIR}/vkquake.png" "${GIT_DIR}"
	cp "${GIT_DIR}/LICENSE.txt" "${GIT_DIR}/debian/LICENSE"
	cp "${SCRIPTDIR}/vkquake-launch.sh" "${GIT_DIR}/vkquake-launch"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_TMP}" || exit
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"

	# enter source dir
	cd "${GIT_DIR}"


	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building static Debian package ${PKGNAME} from source\n"
	sleep 2s

	cd vkQuake/Quake
	make || echo -e "\n==EROR==\nMake failed!"

	#################################################
	# Cleanup
	#################################################


	echo -e "\n==> Would you like to transfer the archive? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# copy files to remote server
		rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
		--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
		${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

		# uplaod local repo changelog
		cp "${GIT_DIR}/debian/changelog" "${SCRIPTDIR}/debian"

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

