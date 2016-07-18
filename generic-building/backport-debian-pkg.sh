#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	backport-debian-pkg.sh.sh
# Script Ver:	3.6.1
# Description:	Attempts to build a deb package from upstream Debian source code.
#		files. Currently only Ubuntu and Debian .dsc files are supported.
#		Supports full package name/versioning changes to match your repo.
#		<!-- This script does not yet support multi-orig tarballs / bz2
#		files, such as llvm-defaults-3-8 -->
#
# See:		https://wiki.debian.org/BuildingFormalBackports
#
# Usage:	./backport-debian-pkg.sh.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
scriptdir="${PWD}"
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)
final_opts=$(echo "${@: -1}")

# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool target(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="${ARCH}"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="${BETA_REPO}"
PKGNAME="$PKGNAME"
PKGNAME="$PKGNAME"
PKGREV="1"
URGENCY="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build dirs
SRC_DIR="${PKGNAME}-${PKGNAME}"
git_dir="${BUILD_DIR}/${SRC_DIR}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install autoconf automake build-essential pkg-config bc debhelper \
	packaging-dev debian-keyring devscripts equivs

}

main()
{

	# get vars
	echo -e "\n==> Setting vars\n"

	echo -e "\nPress ENTER to use last: ${OLD_PKGNAME}"
	read -erp "Target package name: " PKGNAME
	if  [[ "${PKGNAME}" == "" ]]; then PKGNAME="${OLD_PKGNAME}"; fi
	export OLD_PKGNAME="${PKGNAME}"

	# now set the build dir for results
	export BUILD_DIR="${HOME}/build-${PKGNAME}-temp"

	echo -e "\nPress ENTER to use last: ${OLD_PKGVER}"
	read -erp "Target package version: " PKGVER
	if [[ "${PKGVER}" == "" ]]; then PKGVER="${OLD_PKGVER}"; fi
	export OLD_PKGVER="${PKGVER}"

	echo -e "\nPress ENTER to use last: ${OLD_PKGREV}"
	read -erp "Package revision / attempt: " PKGREV
	if [[ "${PKGREV}" == "" ]]; then PKGREV="${OLD_PKGREV}"; fi
	export OLD_PKGREV="${PKGREV}"

	echo -e "\nPress ENTER to use last: ${OLD_ARCH}"
	read -erp "Arch target: " ARCH
	if  [[ "${ARCH}" == "" ]]; then ARCH="${OLD_ARCH}"; fi
	export OLD_ARCH="${ARCH}"

	echo -e "\nPress ENTER to use last: ${OLD_DIST}"
	read -erp "Distribution target: " DIST
	if  [[ "${DIST}" == "" ]]; then DIST="${OLD_DIST}"; fi
	export OLD_DIST="${DIST}"

	echo -e "\nPress ENTER to use last: ${OLD_DSC}"
	read -erp "Paste link to upsteam .dsc: " DSC
	if  [[ "${DSC}" == "" ]]; then DSC="${OLD_DSC}"; fi
	export OLD_DSC="${DSC}"

	# Set projet folder name for uploading built packages

	if [[ "${DIST}" == "brewmaster" ]]; then PROJECT_FOLDER="steamos-tools"; fi
	if [[ "${DIST}" == "jessie" ]]; then PROJECT_FOLDER="debian"; fi
	if [[ "${DIST}" == "jessie-backports" ]]; then PROJECT_FOLDER="debian"; fi

	# Set repo folder full path for rsync

	if [[ "${arg1}" == "--testing" ]]; then

		REPO_FOLDER="/home/mikeyd/packaging/${PROJECT_FOLDER}/incoming_testing"

	else

		REPO_FOLDER="/home/mikeyd/packaging/${PROJECT_FOLDER}/incoming"

	fi

	# create BUILD_DIR
	if [[ -d "${BUILD_DIR}" ]]; then

		sudo rm -rf "${BUILD_DIR}"
		mkdir -p "${BUILD_DIR}"

	else

		mkdir -p "${BUILD_DIR}"

	fi

	# enter build dir
	cd "${BUILD_DIR}" || echo "Cannot enter build directory!" && sleep 5s

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "pbuilder" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"
	sleep 2s

	# Obtain all necessary files specified in .dsc via dget
	# Download only, as unverified sources (say a Ubuntu pkg build on Debian) will not auto-extract
	# Also do not want dpkg-source applying patches before build...(issues then with pbuilder)
	dget -d "${DSC}"

	# Get filename only from DSC URL
	DSC_FILENAME=$(basename "${DSC}")

	# Test if we have an unpacked source or not
	# Ubuntu tends to not have an unpacked source
	# The “-F” marks the delimiter, “$NF” means the last field generated.
	# You can also use extension="${orig##*.}"

	SOURCE_UNPACK_TEST=$(find ${BUILD_DIR} -maxdepth 1 -type d -iname ${PKGNAME}-${PKGVER})
	ORIG_TARBALL=$(find ${BUILD_DIR} -type f -name "*.orig.*")
	ORIG_TARBALL_FILENAME=$(basename ${ORIG_TARBALL})
	ORIG_TARBALL_EXT=$(echo ${ORIG_TARBALL_FILENAME} | awk -F . '{print $NF}')

	# Add more cases below at some point..

	echo -e "\n==> Unpacking original source\n"
	sleep 2s

	# Unpack the original tarball
	case "${ORIG_TARBALL_FILENAME}" in

		*.tar.xz)
		tar -xvf *.orig.tar.xz
		;;

		*.tar.gz)
		tar -xzvf *.orig.tar.gz
		;;

	esac

	# Set the source dir
	SRC_DIR=$(basename `find "${BUILD_DIR}" -maxdepth 1 -type d -iname "${PKGNAME}*"`)

	# Set our suffix for backporting
	# Update any of the below if distro versions change

	if [[ "${DIST}" == "brewmaster" ]]; then

		DIST_CODE="+bsos"

	elif [[ "${DIST}" == "jessie" ]]; then

		DIST_CODE="~bpo8"

	fi

	# Create our new orig tarball after removing the current one
	# Do this rather than rename, so an xz archive is not renamed as a fake gz archive
	# Reminder: the orig tarball does NOT get a revision number!	

	rm -f ${BUILD_DIR}/*.orig.tar.*
	tar -cvzf "${PKGNAME}_${PKGVER}${DIST_CODE}.orig.tar.gz" "${SRC_DIR}"

	# Enter source dir
	cd ${SRC_DIR} || echo "Cannot enter source directory!" && sleep 5s

	# Last safey check - debian folder
	# If the debian folder is in the original souce, keep it.

	if [[ ! -d "${SRC_DIR}/debian" ]]; then

		echo -e "==> debian folder NOT found! unpacking existing\n"

		# no debian folder find and unpack the dget sourced file
		DEBIAN_FOLDER=$(find "${BUILD_DIR}" -type f -name "*.debian.*")

		case "${DEBIAN_FOLDER}" in

			*.tar.xz)
			tar -xvf "${DEBIAN_FOLDER}" -C "${PWD}"
			;;

			*.tar.gz)
			tar -xzvf "${DEBIAN_FOLDER}" -C "${PWD}"
			;;

		esac

	else

		echo "debian dir found!"

	fi

	# clean renaining files (not necessary, but keeps temp build dir clean ^_^ )
	rm ${BUILD_DIR}/*.debian.* ${BUILD_DIR}/*.dsc

	# Check source format
	SOURCE_FORMAT=$(cat debian/source/format | awk '/quilt/ || /native/ {print $2}' | sed -e 's/(//' -e 's/)//')

	# Calculate the ending suffix 
	if [[ "${SOURCE_FORMAT}" == "quilt" ]]; then

		PKGSUFFIX="${DIST_CODE}-${PKGREV}"

	elif [[ "${SOURCE_FORMAT}" == "native" ]]; then

		PKGSUFFIX="${DIST_CODE}${PKGREV}"

	fi

	# update changelog
	# Be sure to include a pacakge revision (e.g. "-1" with "bc_1.0.0+bsos-1") if needed!
	# If a package has an epoch such as "7:ffmpeg_2.7.6-ubuntu", be sure to bump this number 
	# if you already have a package in your repository with a lesser or equal epoch.

	echo -e "\n==> Updating changelog with dch. Adjust as necessary. Be mindful of epochs!"
	sleep 4s

	# Create basic changelog format if it does exist or update
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-bad-version --force-distribution -v "${PKGVER}${PKGSUFFIX}" \
		--package "${PKGNAME}" -D $DIST -u "${URGENCY}" "Backported package. No changes made."
		nano "debian/changelog"

	else

		dch -p --force-bad-version --force-distribution --create -v "${PKGVER}${PKGSUFFIX}" \
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial upload attempt"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Backporting Debian package ${PKGNAME} from source"
	sleep 2s

	# Ask what method

	echo -e "\n==> Use what method? [pbuilder|local]"
	read -erp "Choice: " METHOD

	if [[ "${METHOD}" == "pbuilder" ]]; then

		if ! sudo -E BUILD_DIR=${BUILD_DIR} DIST=${DIST} ARCH=${ARCH} ${BUILDER} \
		${BUILDOPTS}; then

			# back out to scriptdir
			echo -e "\n!!! FAILED TO BACKPORT. See output!!! \n"
			cd "${scriptdir}"

		fi

	elif [[ "${METHOD}" == "local" ]]; then

		# enter dir and attemp to satisfy build deps
		cd ${PKGNAME}*
		if ! sudo mk-build-deps --install --remove; then

			# back out to scriptdir
			echo -e "\n!!! FAILED TO ACQUIRE BUILD-DEPS. See output!!! \n"
			cd "${scritpdir}"

		fi

		# If build deps pass above, go ahead
		dch --local ~bpo80+ --distribution ${DIST} "Rebuild for ${DIST}."

		# Test if we can successfully build the package
		fakeroot debian/rules binary

		# Build a package properly , without GPG signing the package
		dpkg-buildpackage -us -uc

	fi

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

	Showing contents of: ${BUILD_DIR}

	EOF

	ls "${BUILD_DIR}" | grep -E "${PKGNAME}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_DIR}" ]]; then
			rsync -arv -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_DIR}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main

#In case the script fails cd back to scriptdir
cd "${scriptdir}"
