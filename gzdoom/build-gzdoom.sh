#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/mdeguzis/SteamOS-Tools
# Scipt name:	build-gzdoom.sh
# Script Ver:	0.1.1
# Description:	Attmpts to build a deb package from the latest gzdoom source
#		code.
#
# See:		https://github.com/coelckers/gzdoom
#
# Usage:	./build-gzdoom.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

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
SRC_URL="https://github.com/coelckers/gzdoom"
FMOD_FILE="fmodstudioapi10815linux.tar.gz"
FMOD_RELEASE="http://www.fmod.org/download/fmodstudio/api/Linux/${FMOD_FILE}"
TARGET="g2.3.0"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
PKGNAME="gzdoom"
PKGVER=$(echo ${TARGET} | sed 's/g//')
PKGREV="1"
PKGSUFFIX="git+bsos"
DIST="${DIST:=brewmaster}"
URGENCY="low"
UPLOADER="Michael DeGuzis <mdeguzis@gmail.com>"
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
	sudo apt-get install -y --force-yes build-essential pkg-config bc debhelper libmpg123-dev libfluidsynth-dev \
	libsndfile1-dev libsdl2-dev

}

fetch_fmod()
{

	# Obtain FMOD
	# See: https://wiki.debian.org/FMOD
	# See: https://github.com/coelckers/gzdoom/blob/master/src/CMakeLists.txt

	# IMPORTANT! - FMOD must be downloaded from the website first
	# The download is user-authenticated
	# A copy should be in the GitHub directory this script resides in

	wget "http://www.libregeek.org/Linux/files/${FMOD_FILE}" \
	-q -nc --show-progress

	# Unpack FMOD for build

	# You can either use "make install" on the FMOD distribution to put it
	# in standard system locations, or you can unpack the FMOD distribution
	# in the root of the zdoom tree. e.g.:
	# zdoom
	#   docs
	#   fmodapi<version>linux[64] -or simply- fmod
	#   jpeg-6b
	#   ...
	# The recommended method is to put it in the zdoom tree, since its
	# headers are unversioned. Especially now that we can't work properly
	# with anything newer than 4.26.xx, you probably don't want to use
	# a system-wide version.

	mkdir -p "${SRC_DIR}/fmod"

	if [[ -f "${FMOD_FILE}" ]]; then

		# Unpack
		echo -e "\nUnpacking FMOD\n"
		sleep 2s
		tar xzvf fmod*.tar.gz --strip-components=1 -C "${SRC_DIR}/fmod"
		rm -f "${FMOD_VER}"

	else
		echo -e "\nCould not find or unpack FMOD! Exiting...\n" 
		sleep 4s
		exit 1

	fi

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

	# clone
	git clone -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_TMP}" || exit
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" $(basename ${SRC_DIR})

	# Add required files
	cp -r "${SCRIPTDIR}/debian" "${SRC_DIR}"
	cp "${SRC_DIR}/docs/licenses/README.TXT" "${SRC_DIR}/debian/LICENSE"

	# Assess optoin for fmod support
	if [[ "${FMOD_SUPPORT}" == "true" ]]; then

		# fetch files
		fetch_fmod

		# adjust for fmod
		sed -i 's/$[(]FMOD[)]/\-DNO_FMOD=OFF/' "${SRC_DIR}/debian/rules"
		sed -i 's/$[(]OPENAL[)]/\-DNO_OPENAL=ON/' "${SRC_DIR}/debian/rules"

	else

		# adjust for openal
		sed -i 's/$[(]FMOD[)]/\-DNO_FMOD=ON/' "${SRC_DIR}/debian/rules"
		sed -i 's/$[(]OPENAL[)]/\-DNO_OPENAL=OFF/' "${SRC_DIR}/debian/rules"

	fi

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}~${PKGSUFFIX}-${PKGREV}" --package "${PKGNAME}" \
		-D "${DIST}" -u "${URGENCY}" "Upload for ${DIST}"
		vim "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial upload"

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

############################
# source options
############################

# set defaults
REPO_FOLDER="/mnt/server_media_y/packaging/ubuntu/incoming"
FMOD_SUPPORT="false"

while :; do
	case $1 in

		--testing)
			REPO_FOLDER="/mnt/server_media_y/packaging/ubuntu/incoming_testing"
			;;

		--fmod-support|-fmod)
			# Enable fmod
			FMOD_SUPPORT="true"
			;;

		--)
			# End of all options.
			shift
			break
			;;

		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;

		*)
			# no more options
			break
			;;

	esac

	# shift args
	shift

done

# start main
main
