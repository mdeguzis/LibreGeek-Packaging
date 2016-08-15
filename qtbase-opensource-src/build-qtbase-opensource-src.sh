#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-qtbase-opensource-src.sh.sh
# Script Ver:	1.0.0
# Description:	Builds package of QT base
#
# See:		https://github.com/ProfessorKaos64/qt
#		https://wiki.qt.io/Building-Qt-5-from-Git
#
# Usage:	./build-qtbase-opensource-src.sh
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

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming"

fi

GIT_URL="https://github.com/qtproject/qtbase/"
branch="v5.7.0"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"
# Needed to supercede harfbuzz the Valve provides
export APT_PREFS_HACK="true"
PKGNAME="qtbase-opensource-src"
PKGVER="5.7.0"
PKGREV="2"
PKGSUFFIX="git+bsos"
DIST="brewmaster"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set BUILD_TMP
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_TMP}/${SRCDIR}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get install -y --force-yes libfontconfig1-dev libfreetype6-dev \
	libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev \
	libx11-xcb-dev libxcb-glx0-dev

	# Needed if not passing -qt-xcb
	sudo apt-get install -y --force-yes libxcb-keysyms1-dev libxcb-image0-dev \
	libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
	libxcb-randr0-dev libxcb-render-util0-dev libgl1-mesa-dev

	# Needed for qtwebengine building
	sudo apt-get install -y --force-yes libcap-dev libegl1-mesa-dev x11-xserver-utils \
	libxrandr-dev libxss-dev libxcursor-dev libxtst-dev libpci-dev libdbus-1-dev \
	libatk1.0-dev libnss3-dev re2c gperf flex bison libicu-dev libxslt-dev ruby \
	libssl-doc x11proto-composite-dev libasound2-dev libxcomposite-dev

}

main()
{

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	else

		# required for dh_clean
		sudo apt-get install -y --force-yes pkg-kde-tools

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"
	sleep 2s

	if [[ -d "${GIT_DIR}" || -f ${BUILD_TMP}/*.orig.tar.gz ]]; then

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
			git clone -b "${branch}" "${GIT_URL}" "${GIT_DIR}"
			cd "${GIT_DIR}" && git submodule update --init

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
			git clone -b "${branch}" "${GIT_URL}" "${GIT_DIR}"
			cd "${GIT_DIR}" && git submodule update --init

	fi

	# trim git (after confimed working build)
	# rm -rf "${GIT_DIR}/.git"
	
	# Checkout our desired branch now
	cd "${GIT_DIR}" && git checkout "${TARGET_branch}" || exit 1

	#################################################
	# Prep source
	#################################################

	# Trim .git folders
	find "${GIT_DIR}" -name ".git" -type d -exec sudo rm -r {} \;

	# create source tarball
	# For now, do not recreate the tarball if keep was used above (to keep it clean)
	# This way, we can try again with the orig source intact
	# Keep this method until a build is good to go, without error.
	
	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		cd "${BUILD_TMP}"
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"
		
	else
	
		echo -e "\n==> Cleaning old source foldrers for retry"
		sleep 2s
		
		rm -rf *.dsc *.xz *.build *.changes ${GIT_DIR}
		mkdir -p "${GIT_DIR}"
	
		echo -e "\n==> Retrying with prior source tarball\n"
		sleep 2s
		cd "${BUILD_TMP}"
		tar -xzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" -C "${BUILD_TMP}" --totals
		sleep 2s

	fi

	# Try using upstream debian/
	cp -r "${SCRIPTDIR}/debian" "${GIT_DIR}"

	###############################################################
	# build package
	###############################################################

	# enter source dir
	cd "${GIT_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" --package \
		"${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Update to version ${PKGVER}"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" --package \
		"${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial upload"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

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

