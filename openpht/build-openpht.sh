#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-openpht.sh
# Script Ver:	1.0.8
# Description:	Attmpts to builad a deb package from latest plexhometheater
#		github release
#
# See:		https://github.com/RasPlex/OpenPHT
#		https://github.com/plexinc/plex-home-theater-public/blob/pht-frodo/README-BUILD-PLEX.md
#		https://forums.plex.tv/discussion/196117/linux-build#latest
#
# Track:	http://www.preining.info/blog/2015/05/plex-home-theater-1-4-1-for-debian-jessie-and-sid/
# Usage:	./build-openpht.sh
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

# upstream vars
#GIT_URL="https://github.com/plexinc/plex-home-theater-public"
#GIT_URL="https://github.com/ProfessorKaos64/plex-home-theater-public"
GIT_URL="https://github.com/RasPlex/OpenPHT"
TARGET="v1.6.2.123-e23a7eef"
#TARGET="openpht-1.6"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b --debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"		# requires cmake >= 3.1.0 (not in Jessie)
PKGNAME="openpht"
PKGVER="1.6.2"
PKGREV="2"
PKGSUFFIX="${date_short}git+bsos"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_DIRECTORY
export BUILD_DIRECTORY="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_DIRECTORY}/${SRCDIR}"

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
	libtinyxml-dev libmp3lame-dev libva-dev yasm quilt

	# libcec
	sudo apt-get install -y --force-yes libcec3 dcadec1

}

main()
{

	# install prereqs for build
	
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs
	
	else
	
		# cdbs needed for build clean
		sudo apt-get install -y cdbs

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	if [[ -d "${GIT_DIR}" || -f ${BUILD_DIRECTORY}/*.orig.tar.gz ]]; then

		echo -e "==Info==\nGit source files already exist! Remove and [r]eclone or [k]eep? ?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# clean and clone
			sudo rm -rf "${BUILD_DIRECTORY}" && mkdir -p "${BUILD_DIR}"
			git clone -b "${TARGET}" "${GIT_URL}" "${GIT_DIR}"

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
			mkdir -p "${BUILD_DIRECTORY}" || exit 1
			git clone -b "${TARGET}" "${GIT_URL}" "${GIT_DIR}"

	fi

        # copy in debian folder and other files
        cp -r "$scriptdir/debian" "${GIT_DIR}"
	
	# Get latest commit
	cd "${GIT_DIR}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")
	
	# Trim out .git
	rm -rf "${GIT_DIR}/.git"
	
	#################################################
	# Prep source
	#################################################

	# create source tarball
	# For now, do not recreate the tarball if keep was used above (to keep it clean)
	# This way, we can try again with the orig source intact
	# Keep this method until a build is good to go, without error.
	
	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		cd "${BUILD_DIRECTORY}"
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"
		
	else
	
		echo -e "\n==> Cleaning old source folders for retry"
		sleep 2s
		
		rm -rf *.dsc *.xz *.build *.changes ${GIT_DIR}
		mkdir -p "${GIT_DIR}"
	
		echo -e "\n==> Retrying with prior source tarball\n"
		sleep 2s
		cd "${BUILD_DIRECTORY}"
		tar -xzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" -C "${BUILD_DIRECTORY}" --totals
		sleep 2s

	fi

	#################################################
	# Build package
	#################################################

	# enter source dir
	cd "${SRCDIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${urgency}" "Update build/release"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${urgency}" "Initial build"

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
	
	Showing contents of: ${BUILD_DIRECTORY}
	
	EOF

	ls "${BUILD_DIRECTORY}" | grep -E "${PKGVER}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_DIRECTORY}" ]]; then
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_DIRECTORY}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${GIT_DIR}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
