#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/mdeguzis/SteamOS-Tools
# Scipt name:	build-kodi.sh
# Script Ver:	0.3.1
# Description:	Attmpts to build a deb package from the latest kodi source
#		code.
#
# See:		https://github.com/xbmc/xbmc
#
# Usage:	./build-kodi.sh
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
# upstream vars
SRC_URL="https://github.com/xbmc/xbmc"
TARGET="17.3-Krypton"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"
export NO_LINTIAN="false"
export NO_PKG_TEST="false"
PKGNAME="kodi"
PKGREV="1"
EPOCH="2"
PKGVER=$(echo ${TARGET} | sed 's/-Kyrpton//g')
PKGSUFFIX="git${DATER_SHORT}+bsos"
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

	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	# TODO - fix up
	sudo apt-get install -y --force-yes build-essential 

}

main()
{

	# install prereqs for build
	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and get latest commit tag
	if [[ -d "${SRC_DIR}" || -f ${BUILD_TMP}/*.orig.tar.gz ]]; then

		echo -e "==Info==\nGit source files already exist! Remove and [r]eclone or [c]lean? ?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# clean and clone
			sudo rm -rf "${BUILD_TMP}" && mkdir -p "${BUILD_TMP}"
			git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

		else

			echo -e "\n==> Cleaning files...\n"
			sleep 2s
			# Clean
			rm -fv "${BUILD_TMP}/*.tar.gz"
			rm -fv "${BUILD_TMP}/*.tar.xz"
			rm -fv "${BUILD_TMP}/*.build"
			rm -fv "${BUILD_TMP}/*.log"
			rm -fv "${BUILD_TMP}/*.deb"
			rm -fv ${SRC_DIR}/tools/depends/target/libdvdread/*.tar.gz
			rm -fv ${SRC_DIR}/tools/depends/target/libdvdnav/*.tar.gz
			rm -fv ${SRC_DIR}/tools/depends/target/libdvdcss/*.tar.gz
			rm -fv ${SRC_DIR}/tools/depends/target/ffmpeg/*tar.gz
			rm -rfv ${SRC_DIR}/debian
			cd "${SRC_DIR}"
			git clean -f
			git reset --hard
			git checkout "${TARGET}"
			git pull

		fi

	else

			echo -e "\n==> Git directory does not exist. cloning now...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# create and clone to current dir
			mkdir -p "${BUILD_TMP}" || exit 1
			git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

	fi

	# New build rules expect tarballs in certain depends locations, fetch
	# Make sure to doublecheck the Kodi team build log n Launchpad for any changes
	echo -e "==> Fetching extra required tarballs\n"
	wget -O "${SRC_DIR}/tools/depends/target/libdvdread/libdvdread-master.tar.gz" "https://github.com/xbmc/libdvdread/archive/master.tar.gz" -nc --show-progres || exit 1
	wget -O "${SRC_DIR}/tools/depends/target/libdvdnav/libdvdnav-master.tar.gz" "https://github.com/xbmc/libdvdnav/archive/master.tar.gz" -nc --show-progres || exit 1
	wget -O "${SRC_DIR}/tools/depends/target/libdvdcss/libdvdcss-master.tar.gz" "https://github.com/xbmc/libdvdcss/archive/master.tar.gz" -nc --show-progres || exit 1
	wget -O "${SRC_DIR}/tools/depends/target/ffmpeg/ffmpeg-3.1.6.tar.gz" "https://github.com/xbmc/FFmpeg/archive/3.1.6-Krypton.tar.gz" -nc --show-progres || exit 1
			
	#################################################
	# Prepare sources
	#################################################

	cd "${BUILD_TMP}" || exit 1

	# create source tarball

	echo -e "\n==> Creating original tarball\n"
	sleep 2s
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

	# Add required files
	cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

	#################################################
	# Build package
	#################################################

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-bad-version --force-distribution -v "${EPOCH}:${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Update snapshot"
		vim "debian/changelog"

	else

		dch -p --create --force-distribution -v "${EPOCH}:${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial build"
		vim "debian/changelog"

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

