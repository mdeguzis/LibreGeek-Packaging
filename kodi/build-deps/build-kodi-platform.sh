#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/mdeguzis/SteamOS-Tools
# Scipt Name:	build-platform.sh
# Script Ver:	0.7.5
# Description:	Attmpts to build a deb package from kodi-platform git source
#
# See:		http://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/
# Usage:	build-kodi-platform.sh
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

	REPO_FOLDER="/mnt/server_media_y/packaging/steamos-tools/incoming_testing"
	
else

	REPO_FOLDER="/mnt/server_media_y/packaging/steamos-tools/incoming"
	
fi

# upstream URL
SRC_URL="https://github.com/xbmc/kodi-platform"
TARGET="master"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export export STEAMOS_TOOLS_BETA_HOOK="true"
PBUILDER_HOOKS="$HOME/pbuilder/hooks/steamos-tools-beta"
PKGNAME="kodiplatform"
BUILDER="pdebuild"
PKGVER="17.0.0"
PKGREV="1"
PKGSUFFIX="git+bsos${PKGREV}"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="mdeguzis"

# set build directories
unset BUILD_TMP
export BUILD_TMP="${BUILD_TMP:=${HOME}/package-builds/build-${PKGNAME}-tmp}"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{

	echo -e "\n==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config checkinstall bc python \
	cmake libtinyxml-dev kodi-addon-dev libplatform-dev

	# See: https://github.com/xbmc/kodi-platform/pull/16
 	# For now, the likely TARGET package for Jarvis will be platform, not the renamed p8-platform

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

	# Clone upstream source code

	echo -e "\n==> Obtaining upstream source code\n"
	git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"
	cd "${SRC_DIR}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# Trim .git folders
	find "${SRC_DIR}" -name "*.git" -type d -exec sudo rm -r {} \;

	# create source tarball
	cd ${BUILD_TMP}
	tar -cvzf "${PKGNAME}_${PKGVER}.orig.tar.gz" $(basename ${SRC_DIR})

	# emter source dir
	cd "${SRC_DIR}"

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-bad-version --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" \
		"Update to the latest release"
		vim "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" \
		"Update to the latest release"

	fi
 
	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	HOOKDIR=$PBUILDER_HOOKS DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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
			--filter="merge ${HOME}/.config/libregeek-packaging/repo-filter.txt" \
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

