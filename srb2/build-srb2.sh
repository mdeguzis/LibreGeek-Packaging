#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-srb2.sh
# Script Ver:	1.0.8
# Description:	Attmpts to builad a deb package from latest Sonic Robo Blast 2
#		github release
#
# See:		https://github.com/STJr/SRB2
# See:https://github.com/STJr/SRB2/issues/45
#
# Usage:	./build-srb2.sh [opts]
# Opts:		[--build-data|--build-data-only]
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
SRC_URL="https://github.com/STJr/SRB2"
TARGET="SRB2_release_2.1.16a"
ASSETS_VER="SRB2-v2115-assets-2"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="false"
export NO_LINTIAN="false"
export NO_PKG_TEST="false"
PKGNAME="srb2"
PKGVER="$(echo ${TARGET} | sed 's/SRB2_release_//')"
PKGREV="1"
PKGSUFFIX="git+bsos"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="LibreGeek Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# Assets vars
PKGVER_DATA="2.1.14"
EPOCH_DATA="1"
PKGREV_DATA="1"
PKGNAME_DATA="srb2-data"
DATA_DIR="assets"

# set build directories
unset BUILD_TMP
export BUILD_TMP="${BUILD_TMP:=${HOME}/package-builds/build-${PKGNAME}-tmp}"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear

	if [[ "$arg1"  == '--build-data' ]]; then
		echo -e "==INFO==\nBuilding both main data package and data pacakge\n"
	fi

	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc debhelper \
	libpng12-dev libglu1-mesa-dev libgl1-mesa-dev nasm:i386 libsdl2-dev libsdl2-mixer-dev \
	libgme-dev clang cmake libgl1-mesa-dev libgme-dev clang-3.6

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


	else

		# still need 7zip
		sudo apt-get install p7zip-full

	fi


	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"

	# clone (use recursive to get the assets folder)
	git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

	echo -e "\n==> Fetching data files\n"

	DATAFILES="srb2.srb zones.dta player.dta rings.dta music.dta"

	for file in ${DATAFILES}; 
	do
		wget -P  "${SRC_DIR}/assets" "http://alam.srb2.org/SRB2/${PKGVER_DATA}-Final/Resources/${file}" \
		-nc -q --show-progress
	done


	if [[ "$arg1" != "--build-data-only" ]]; then

		# get suffix from TARGET commit (stable TARGETs for now)
		cd "${SRC_DIR}"

		#################################################
		# Prepare package (main)
		#################################################

		echo -e "\n==> Creating original tarball\n"
		sleep 2s

		# enter build dir to package attmpt
		cd "${BUILD_TMP}"

		# TEMP, fix debian/docs
		rm -rf "${SRC_DIR}/debian/docs"
		echo "README.md" > "${SRC_DIR}/debian/docs"

		# Trim .git folders
		find "${SRC_DIR}" -name "*.git" -type d -exec sudo rm -r {} \;

		# create source tarball
		cd "${BUILD_TMP}"
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

		# Add our debian files
		cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

		# enter source dir
		cd "${SRC_DIR}"

		echo -e "\n==> Updating changelog"
		sleep 2s

		# update changelog with dch
		if [[ -f "debian/changelog" ]]; then

			dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}${PKGREV}" --package "${PKGNAME}" \
			-D "${DIST}" -u "${URGENCY}"
			"Update release to ${PKGVER}"

		else

			dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}${PKGREV}" \
			--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}"

		fi


		#################################################
		# Build Debian package (main)
		#################################################

		echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
		sleep 2s

		#  build
		DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	fi

	if [[ "$arg1" == "--build-data" || "$arg1" == "--build-data-only" ]]; then

		#################################################
		# Prepare Debian package (data) - if needed
		#################################################

		# Required to fetch assets within Makefile
		export USE_NETWORK="yes"

		echo -e "\n==> Building Debian package ${PKGNAME_data} from source\n"
		sleep 2s

		echo -e "...Stripping uneeded dirs for data package\n"
		sleep 2s

		# strip unecessary dirs
		STRIP_DIRs="android CMakeLists.txt debian objs srb2.png Android.mk \
		comptime.bat doc README.md SRB2_Release.props appveyor.yml comptime.mk \
		Doxyfile SRB2.cbp srb2-vc10.sln comptime.props extras SRB2_common.props \
		srb2-vc9.sln bin comptime.sh libs SRB2_Debug.props src cmake cpdebug.mk \
		LICENSE Srb2.dev tools"

		# Run validation
		for file_or_folder in ${STRIP_DIRs};
		do

			rm -rv "${SRC_DIR}/${file_or_folder}"

		done

		# create source tarball
		cd "${BUILD_TMP}/${PKGNAME}-${PKGVER}"
		tar -cvzf "${PKGNAME_data}_${PKGVER_DATA}.orig.tar.gz" $(basename ${DATA_DIR})

		# enter source dir
		cd "${DATA_DIR}"

	 	# update changelog with dch
		if [[ -f "debian/changelog" ]]; then

			dch -p --force-distribution -v "${EPOCH_DATA}:${PKGVER_DATA}+${PKGSUFFIX}${PKGREV_DATA}" \
			--package "${PKGNAME_DATA}" -D "${DIST}" -u "${URGENCY}" \
			"Update for SRB2 ${PKGVER}"
			nano "debian/changelog"

		else

			dch -p --create --force-distribution -v "${EPOCH_DATA}:${PKGVER_DATA}+${PKGSUFFIX}${PKGREV_DATA}" \
			--package "${PKGNAME_DATA}" -D "${DIST}" -u "${URGENCY}"

		fi

		#################################################
		# Build Debian package (data)
		#################################################

		echo -e "\n==> Building Debian package ${PKGNAME_DATA} from source\n"
		sleep 2s

		#  build
		DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	# end build data run
	fi

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

	# back out of build tmp to script dir if called from git clone
	if [[ "${SCRIPTDIR}" != "" ]]; then
		cd "${SCRIPTDIR}" || exit
	else
		cd "${HOME}" || exit
	fi

	# inform user of packages
	cat<<- EOF
	#################################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependency errors listed above.
	#################################################################

	EOF

	echo -e "Showing contents of: ${BUILD_TMP}: \n"
	ls "${BUILD_TMP}" | grep -E *${PKGNAME}*

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

