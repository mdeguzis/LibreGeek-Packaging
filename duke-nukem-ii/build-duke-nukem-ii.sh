#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	build-duke-nukem-ii.sh
# Script Ver:	0.1.1
# Description:	Attmpts to build a deb package from the latest duke-nukem-ii source
#		code.
#
# See:		https://github.com/lethal-guitar/RigelEngine
#
# Usage:	./build-duke-nukem-ii.sh
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
SRC_URL="https://github.com/lethal-guitar/RigelEngine"
TARGET="master"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="true"
export NO_APT_PREFS="false"
PKGNAME="duke-nukem-ii"
PKGVER="0.1.0"
PKGREV="1"
PKGSUFFIX="${DATE_SHORT}git+bsos"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set build directories and build vars
retry="no"
export BUILD_TMP="${BUILD_TMP:-${HOME}/package-builds/build-${PKGNAME}-tmp}"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"


install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential \
	cmake libboost-all-dev libsdl2-dev libsdl2-mixer-dev
}

main()
{

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "sbuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"
	sleep 1s

	if [[ -d "$SRC_DIR" ]]; then

		echo -e "\n==Info==\nSource folder already exists! Reclone [r] or pull [p]?\n"
		sleep 1s
		read -ep "Choice: " src_choice

		if [[ "$src_choice" == "p" ]]; then

			# attmpt to pull the latest source first
			echo -e "\n==> Attmpting git pull..."
			sleep 2s
			retry="yes"

			# attmpt git pull, if it doesn't complete reclone
			if ! git pull; then

				# command failure
				echo -e "\n==Info==\nSource directory pull failed. Removing and cloning...\n"
				sleep 2s
				rm -rf "${BUILD_TMP}" && mkdir -p "${BUILD_DIR}"
				git clone --recursive -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

			fi

		elif [[ "$src_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			rm -rf "${BUILD_TMP}" && mkdir -p "${BUILD_DIR}"
			git clone --recursive -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

		else

			echo -e "\n==> Source directory does not exist. cloning now...\n"
			sleep 2s
			mkdir -p  "${BUILD_TMP}"
			git clone --recursive -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

		fi

	else

			echo -e "\n==> Source directory does not exist. cloning now...\n"
			sleep 2s
			mkdir -p  "${BUILD_TMP}"
			# create and clone to current dir
			git clone --recursive -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

	fi

	# Copy in extras
#	cp "${SCRIPTDIR}/duke-nukem-ii.png" "${SRC_DIR}"

	################################################
	# Prepare sources
	#################################################

	cd "${BUILD_TMP}" || exit 1

	# Trim .git folders
	# find "${SRC_DIR}" -name "*.git" -type d -exec sudo rm -r {} \;

	# create source tarball
	# For now, do not recreate the tarball if keep was used above (to keep it clean)
	# This way, we can try again with the orig source intact
	# Keep this method until a build is good to go, without error.

	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

	else

		echo -e "\n==> Cleaning old source folders for retry"
		sleep 2s

		rm -rf *.dsc *.xz *.build *.changes ${SRC_DIR}
		mkdir -p "${SRC_DIR}"

		echo -e "\n==> Retrying with prior source tarball\n"
		sleep 2s
		tar -xzf ${PKGNAME}_*.orig.tar.gz -C "${BUILD_TMP}" --totals
		sleep 2s

	fi

	# copy in debian folder
	cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"

	################################################
	# Build package
	#################################################

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Update release"
		nano "debian/changelog"

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
