#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-openpht.sh
# Script Ver:	1.0.8
# Description:	Attmpts to build a deb package from latest openpht
#		github release. This script builds a variant that uses internal
#		ffmpeg
#
# See:		https://github.com/RasPlex/OpenPHT
#		https://github.com/plexinc/plex-home-theater-public/blob/pht-frodo/README-BUILD-PLEX.md
#
# Usage:	./build-openpht.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set default variables
#################################################

arg1="$1"
SCRIPTDIR=$(pwd)
TIME_START=$(date +%s)
TIME_STAMP_START=(`date +"%T"`)
retry="no"

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
#SRC_URL="https://github.com/plexinc/plex-home-theater-public"
#SRC_URL="https://github.com/ProfessorKaos64/plex-home-theater-public"
SRC_URL="https://github.com/RasPlex/OpenPHT"
TARGET="openpht-1.7"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"		# requires cmake >= 3.1.0 (not in Jessie)
PKGNAME="openpht-unstable"
PKGVER=$(echo ${TARGET} | sed 's/openpht-//')
PKGREV="2"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set BUILD_TMP
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc \
	cmake debhelper cdbs unzip libboost-dev zip libgl1-mesa-dev libglu1-mesa-dev \
	libglew-dev libmad0-dev libjpeg-dev libsamplerate-dev libogg-dev libvorbis-dev \
	libfreetype6-dev libfontconfig-dev libbz2-dev libfribidi-dev libsqlite3-dev \
	libasound2-dev libpng12-dev libpcre3-dev liblzo2-dev libcdio-dev libsdl-dev \
	libsdl-image1.2-dev libsdl-mixer1.2-dev libenca-dev libjasper-dev libxt-dev \
	libxmu-dev libcurl4-gnutls-dev libdbus-1-dev libpulse-dev libavahi-common-dev \
	libavahi-client-dev libxrandr-dev libmpeg2-4-dev libass-dev libflac++-dev \
	libflac-dev zlib1g-dev libsmbclient-dev libiso9660-dev libssl-dev libvdpau-dev \
	libmicrohttpd-dev libmodplug-dev librtmp-dev curl libyajl-dev libboost-thread-dev \
	libboost-system-dev libplist-dev libcec-dev libudev-dev libshairport-dev libtiff5-dev \
	libtinyxml-dev libmp3lame-dev libva-dev yasm quilt libavcodec-ffmpeg-dev \
	libavfilter-ffmpeg-dev libavformat-ffmpeg-dev libavutil-ffmpeg-dev \
	libpostproc-ffmpeg-dev libswscale-ffmpeg-dev libswresample-ffmpeg-dev libavdevice-ffmpeg-dev

	# libcec
	sudo apt-get install -y --force-yes libcec3 dcadec1

}

main()
{

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	else

		# cdbs needed for build clean
		sudo apt-get install -y cdbs

	fi

	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	if [[ -d "${SRC_DIR}" || -f ${BUILD_TMP}/*.orig.tar.gz ]]; then

		echo -e "==Info==\nGit source files already exist! Remove and [r]eclone or [k]eep? ?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# clean and clone
			sudo rm -rf "${BUILD_TMP}" && mkdir -p "${BUILD_DIR}"
			git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

		else

			# Unpack the original source later on for  clean retry
			# set retry flag
			retry="yes"

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

        # copy in debian folder and other files
        cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

	# Get latest commit
	cd "${SRC_DIR}"
	# Set suffix based on revisions
	LATEST_COMMIT=$(git log -n 1 --pretty=format:"%h")
	PKGSUFFIX="git${DATE_SHORT}.${LATEST_COMMIT}"

	# Trim out .git
	rm -rf "${SRC_DIR}/.git"
	
	#################################################
	# Prep source
	#################################################

	# Trim .git folders
	find "${SRC_DIR}" -name "*.git" -type d -exec sudo rm -r {} \;

	# create source tarball
	# For now, do not recreate the tarball if keep was used above (to keep it clean)
	# This way, we can try again with the orig source intact
	# Keep this method until a build is good to go, without error.

	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		cd "${BUILD_TMP}"
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

	else

		echo -e "\n==> Cleaning old source folders for retry"
		sleep 2s

		rm -rf *.dsc *.xz *.build *.changes ${SRC_DIR}
		mkdir -p "${SRC_DIR}"

		echo -e "\n==> Retrying with prior source tarball\n"
		sleep 2s
		cd "${BUILD_TMP}"
		tar -xzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" -C "${BUILD_TMP}" --totals
		sleep 2s

	fi

	#################################################
	# Build package
	#################################################

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" \
		"Update build/release to latest commit ${latest_commit}" && nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial build"

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

