#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/Libregeek-Packaging
# Scipt Name:	build-godot.sh
# Script Ver:	0.5.1
# Description:	Attempts to build a deb package from latest godot
#		github release
#
# See:		https://github.com/godotengine/godot
#
# Usage:	build-.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)


# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool target(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi

if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/mnt/server_media_x/packaging/ubuntu/incoming_testing"

else

	REPO_FOLDER="/mnt/server_media_x/packaging/ubuntu/incoming"

fi

# upstream vars
SRC_URL="https://github.com/godotengine/godot"
TARGET="2.1.1-stable"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export BUILD_DEBUG="true"
export STEAMOS_TOOLS_BETA_HOOK="false"
export USE_NETWORK="no"
PKGNAME="godot"
PKGVER=$(echo ${TARGET} | sed 's/-stable//')
PKGREV="1"
DIST="${DIST:=yakkety}"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_TMP
export BUILD_TMP="${HOME}/build-${PKGNAME}-temp"
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGVER}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install autoconf automake build-essential bc debhelper \
 	gcc python scons libx11-dev pkg-config libxcursor-dev libasound2-dev libfreetype6-dev \
 	libgl1-mesa-dev libglu-dev libssl-dev libxinerama-dev libudev-dev

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

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and TARGET

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone  -b "${TARGET}" "${SRC_URL}" "${SRC_DIR}"

        # Set suffix based on revisions
        cd "${SRC_DIR}"
        LATEST_COMMIT=$(git log -n 1 --pretty=format:"%h")

        # Set PKGSUFFIX based on Ubuntu DIST
        case "${DIST}" in

                trusty)
                PKGSUFFIX="ubuntu14.04.5"
                ;;

                xenial)
                PKGSUFFIX="ubuntu16.04.1"
                ;;

                yakkety)
                PKGSUFFIX="ubuntu16.10"
                ;;

        esac

	# Add art / other files
	cp "${scriptdir}/godot.png" "${SRC_DIR}"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_TMP}"
	tar -cvzf "${PKGNAME}_${PKGVER}.orig.tar.gz" $(basename ${SRC_DIR})

	# Add debian dir
	cp -r "${scriptdir}/debian" "${SRC_DIR}"

	# enter source dir
	cd "${SRC_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# Create basic changelog format if it does exist or update
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}-${PKGREV}~${PKGSUFFIX}" \
		--package "${PKGNAME}" -D $DIST -u "${urgency}" \
		"Initial upload attempt"
		nano "debian/changelog"

	else

		dch -p --force-distribution --create -v "${PKGVER}-${PKGREV}~${PKGSUFFIX}" \
		--package "${PKGNAME}" -D "${DIST}" \
		-u "${urgency}" "Initial upload attempt"
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

	Showing contents of: ${BUILD_TMP}

	EOF

	ls "${BUILD_TMP}" | grep -E "${PKGVER}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_TMP}" ]]; then

			rsync -arv -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/libregeek-packaging/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# copy local repo changelog
			cp "${SRC_DIR}/debian/changelog" "${SCRIPTDIR}/debian"

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
