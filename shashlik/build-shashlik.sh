#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-shashlik.sh
# Script Ver:	1.0.0
# Description:	Builds simple pacakge for using shashlik, and Android emulator
#
# See:		https://github.com/shashlik/old-shashlik/wiki/Building
#
# Usage:	build-sprunge.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

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
GIT_URL="https://github.com/shashlik/shashlik-manifest"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="debuild"
# Are we going to distribute the orig. souce here? The archive is huge.
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
export USE_NETWORK="yes"
PKGNAME="shashlik-unstable"
PKGVER="0.9.3"
PKGREV="1"
PKGSUFFIX="${date_short}git+bsos"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_TMP
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_TMP}/${PKGNAME}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential bc debhelper git-core curl repo
	
	# Get repo
	sudo wget -P /usr/bin "https://storage.googleapis.com/git-repo-downloads/repo" -q -nc --show-progress
	sudo chmod +x /usr/bin/repo

}

main()
{
	
	# install prereqs for build
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs
		
	else

		# Still need to clone and install repo
		sudo wget -P /usr/bin "https://storage.googleapis.com/git-repo-downloads/repo" -q -nc --show-progress
		sudo chmod +x /usr/bin/repo

	fi

	# This repo is HUGE, so allow it to be kept for subsequent tries
	
	echo -e "\n==> Obtaining upstream source code\n"
	
	if [[ -f "${BUILD_TMP}/${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" ]]; then

		echo -e "==Info==\nSource files already exist! Remove and [r]eclone or [k]eep? ?\n"
		sleep 1s
		read -erp "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# clean and clone
			# We are dumping a lof of repo's into the build dir, so compact them into SRCDIR
			sudo rm -rf "${BUILD_TMP}" && mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}"
			mkdir -p "${SRCDIR}" && cd "${SRCDIR}"
			repo init -u "${GIT_URL}"
			repo sync

		else

			# Unpack the original source later on for  clean retry
			# set retry flag
			retry="yes"

		fi

	else

			echo -e "\n==> Source directory files do not exist, or are incomplete. Cloning now...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# create and clone to current dir
			# We are dumping a lof of repo's into the build dir, so compact them into SRCDIR
			mkdir -p "${BUILD_TMP}" && cd "${BUILD_DIR}"
			mkdir -p "${SRCDIR}" && cd "${SRCDIR}"
			repo init -u "${GIT_URL}"
			repo sync

	fi

	#################################################
	# prep source
	#################################################

	# Enter main build dir to pack the tarball or try again
	cd "${BUILD_TMP}" || exit 1

	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"

	else

		echo -e "\n==> Cleaning old source folders for retry"
		sleep 2s

		# clean specific files
		rm -rf *.dsc *.xz *.build *.changes "${SRCDIR}"

		echo -e "\n==> Retrying with prior source tarball. Unpacking, please wait...\n"
		sleep 2s
		tar -xzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" -C "${BUILD_TMP}" --totals
		sleep 2s

	fi

	# Add required files
	cp -r "${scriptdir}/debian" "${SRCDIR}" || exit 1

	#################################################
	# Build package
	#################################################

	# enter source dir
	cd "${SRCDIR}" || exit 1

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" --package "${PKGNAME}" \
		-D "${DIST}" -u "${urgency}" "Update to the latest commits"
		nano "debian/changelog"
	
	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" --package "${PKGNAME}" \
		-D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"

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
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)

	# output finish
	echo -e "\nTime started: ${time_stamp_start}"
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

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		if [[ -d "${BUILD_TMP}" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}


			# uplaod local repo changelog
			cp "${GIT_DIR}/debian/changelog" "${scriptdir}/debian"

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
