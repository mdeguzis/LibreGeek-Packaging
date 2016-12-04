#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	backport-debian-pkg.sh.sh
# Script Ver:	3.9.2
# Description:	Attempts to build a deb package from upstream Debian source code.
#		files. Currently only Ubuntu and Debian .dsc files are supported.
#		Supports full package name/versioning changes to match your repo.
#		<!-- This script does not yet support multi-orig tarballs / bz2
#		files, such as llvm-defaults-3-8 -->
# See:		https://wiki.debian.org/BuildingFormalBackports
#
# Usage:	./backport-debian-pkg.sh.sh [option-set]
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
SCRIPTDIR="${PWD}"
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)
FINAL_OPTS=$(echo "${@: -1}")

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
# Start with default add more depending on options sourced
BUILDOPTS=("--debbuildopts -sa")
PATCH_REMOVE="false"
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="$PKGNAME"
PKGREV="1"
URGENCY="low"
uploader="Michael DeGuzisd <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# Initial vars for other objects
EXTRA_OPTS=()
TEST_REPO="false"
BETA_REPO=""
RETRY_BUILD="false"
FILE=""
UNPACK_ALL="false"
USER_COMMANDS="false"
DEB_BUILD_PROFILES=""
export DGET_OPTS="-x"		# default
export USE_NETWORK="no"
export NO_APT_PREFS="false"
export NO_PKG_TEST="false"
export NO_LINTIAN="false"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install autoconf automake build-essential pkg-config bc debhelper \
	packaging-dev debian-keyring devscripts equivs

}

function_set_vars()
{

	echo -e "\n==> Setting vars"

	echo -e "\nPress ENTER to use last: ${OLD_PKGNAME}"
	read -erp "Target package name: " PKGNAME
	if  [[ "${PKGNAME}" == "" ]]; then PKGNAME="${OLD_PKGNAME}"; fi
	export OLD_PKGNAME="${PKGNAME}"

	# now set the build dir for results
	unset BUILD_TMP
	export BUILD_TMP="${BUILD_TMP:-${HOME}/package-builds/build-${PKGNAME}-tmp}"

	echo -e "\nPress ENTER to use last: ${OLD_PKGVER}"
	read -erp "Target package version: " PKGVER
	if [[ "${PKGVER}" == "" ]]; then PKGVER="${OLD_PKGVER}"; fi
	export OLD_PKGVER="${PKGVER}"

	echo -e "\nPress ENTER to use last: ${OLD_PKGREV}"
	read -erp "Package revision / attempt: " PKGREV
	if [[ "${PKGREV}" == "" ]]; then PKGREV="${OLD_PKGREV}"; fi
	export OLD_PKGREV="${PKGREV}"

        echo -e "\nPress ENTER to use last: ${OLD_BACKPORTREV}"
        read -erp "Backport revision / attempt: " BACKPORTREV
        if [[ "${BACKPORTREV}" == "" ]]; then BACKPORTREV="${OLD_BACKPORTREV}"; fi
        export OLD_BACKPORTREV="${BACKPORTREV}"

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
	if [[ "${DIST}" == "brewmaster-testing" ]]; then PROJECT_FOLDER="steamos-tools"; fi
	if [[ "${DIST}" == "jessie" ]]; then PROJECT_FOLDER="debian"; fi
	if [[ "${DIST}" == "jessie-backports" ]]; then PROJECT_FOLDER="debian"; fi
	if [[ "${DIST}" == "trusty" ]]; then PROJECT_FOLDER="ubuntu"; fi
	if [[ "${DIST}" == "xenial" ]]; then PROJECT_FOLDER="ubuntu"; fi
	if [[ "${DIST}" == "yakkety" ]]; then PROJECT_FOLDER="ubuntu"; fi

	# Set repo folder destination
	if [[ "${TEST_REPO}" == "false" ]]; then

		REPO_FOLDER="/mnt/server_media_y/packaging/${PROJECT_FOLDER}/incoming"

	elif [[ "${TEST_REPO}" == "true" ]]; then


		REPO_FOLDER="/mnt/server_media_y/packaging/${PROJECT_FOLDER}/incoming_testing"

	fi

	# Beta repo evaluation
	if [[ -n "${BETA_REPO}" ]]; then

		case ${BETA_REPO} in

			steamos-tools)
			export STEAMOS_TOOLS_BETA_HOOK="true"
			;;

			*)
			echo -e "\nERROR: Invalid beta repo!\n"
			sleep 2s
			;;
		esac

	else

		BETA_REPO="none"

	fi

}

function_setup_env()
{

	if [[ -d "${BUILD_TMP}" && "${RETRY_BUILD}" == "false" ]]; then

		sudo rm -rf "${BUILD_TMP}"
		mkdir -p "${BUILD_TMP}"

	elif [[ "${RETRY_BUILD}" == "true" ]]; then

		echo -e "\nRetrying build\n"

	else

		mkdir -p "${BUILD_TMP}"

	fi

	# enter build dir
	cd "${BUILD_TMP}" || echo "Cannot enter build directory!" && sleep 5s

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "suild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

}

function_get_source()
{

	# Review options first in case things are not what the user wants

	cat<<-EOF

	============================
	Please review
	============================

	Buidler: ${BUILDER}
	Distribution: ${DIST}
	ARCH: ${ARCH}
	Builder options: ${BUILDOPTS}
	Beta repo: ${BETA_REPO}
	Repo folder: ${REPO_FOLDER}
	Extra options: ${EXTRA_OPTS}

	Press any key to continue
	EOF

	read -erp "" FAKE_ENTER_KEY


	# Clone upstream source code and branch

	if [[ "${RETRY_BUILD}" == "false" ]]; then

		echo -e "==> Obtaining upstream source code\n"
		sleep 2s

		# Obtain all necessary files specified in .dsc via dget
		dget "${DGET_OPTS}" "${DSC}"

		# Check source format from dsc file
		SOURCE_FORMAT=$(cat ${BUILD_TMP}/${PKGNAME}*.dsc | awk '/quilt/ || /native/ {print $3}' | sed -e 's/(//' -e 's/)//')

		# Calculate the ending suffix for quilt or native
		if [[ "${SOURCE_FORMAT}" == "quilt" ]]; then

			PKGREV="-${PKGREV}"

		elif [[ "${SOURCE_FORMAT}" == "native" ]]; then

			PKGSUFFIX="~${DIST_CODE}+${BACKPORTREV}"
			
			# Native does not get a pgk rev
			unset PKGREV

		fi

		# Get filename only from DSC URL
		DSC_FILENAME=$(basename "${DSC}")

		# Test first If we have multiple original archives
		# Some packages, like llvm-toolchain, contain multiple bz2 archives

		if [[ "$(find ${BUILD_TMP} -name "*.bz2*" | wc -l)" -gt "1" ]]; then

			# Set flag
			ORIG_MULTI="yes"

		else

			# set flag
			ORIG_MULTI="no"

		fi

	fi

	# Set our suffix for backporting
	# Update any of the below if distro versions change
	# Set pkgver on Ubuntu to include everything except revision so 
	# Multi release uploads work fine
	# LaunchPad will not allow an orig. tarball under the same version, so
	# backporting the same package to multiple dists is tough

	# unset pkgrev so it isn't tacked on the end for non-PPAs

	case "${DIST}"  in

		brewmaster)
		DIST_CODE="bsos"
		PKGSUFFIX="${PKGREV}~${DIST_CODE}+${BACKPORTREV}"
		unset PKGREV
		;;

		brewmaster-tesing)
		DIST_CODE="bsos"
		PKGSUFFIX="${PKGREV}~${DIST_CODE}+${BACKPORTREV}"
		unset PKGREV
		;;

		jessie)
		DIST_CODE="bpo8"
		PKGSUFFIX="${PKGREV}~${DIST_CODE}+${BACKPORTREV}"
		unset PKGREV
		;;

		jessie-backports)
		DIST_CODE="bpo8"
		PKGSUFFIX="${PKGREV}~${DIST_CODE}+${BACKPORTREV}"
		unset PKGREV
		;;

                trusty)
                DIST_CODE="trusty"
		PKGVER="${PKGVER}~${DIST_CODE}${BACKPORTREV}"
		PKGREV="-${PKGREV}"
                ;;

		xenial)
		DIST_CODE="xenial"
		PKGVER="${PKGVER}~${DIST_CODE}${BACKPORTREV}"
		PKGREV="-${PKGREV}"
		;;

		yakkety)
		DIST_CODE="yakkety"
		PKGVER="${PKGVER}~${DIST_CODE}${BACKPORTREV}"
		PKGREV="-${PKGREV}"
		;;

	esac

}

function_backport_config()
{

	# Test if we have an unpacked source or not
	# Ubuntu tends to not have an unpacked source
	# The “-F” marks the delimiter, “$NF” means the last field generated.
	# You can also use extension="${orig##*.}"

	SOURCE_UNPACK_TEST=$(find ${BUILD_TMP} -maxdepth 1 -type d -iname "${PKGNAME}*")
	ORIG_TARBALL=$(find ${BUILD_TMP} -type f -name "*.orig.*")

	# Account for pacakges (like quake2) that only list a dsc and xz archive
	if [[ "${ORIG_TARBALL}" == "" ]]; then

		# we must be working only with a .xz archive, sans "orig" in filename
		ORIG_TARBALL=$(find ${BUILD_TMP} -type f -name "*.xz")

	fi

	# Declare rest of original source
	ORIG_TARBALL_FILENAME=$(basename ${ORIG_TARBALL})
	ORIG_TARBALL_EXT=$(echo ${ORIG_TARBALL_FILENAME} | awk -F . '{print $NF}')

	# Add more cases below at some point..

	if [[ "${RETRY_BUILD}" == "false" ]]; then

		echo -e "\n==> Unpacking original source\n"
		sleep 2s

		# Unpack the original tarball
		case "${ORIG_TARBALL_FILENAME}" in

			*.tar.bz2)
			tar -xvjf *.tar.bz2
			;;

			*.tar.xz)
			tar -xvf *.orig.tar.xz
			;;

			*.tar.gz)
			tar -xvzf *.orig.tar.gz
			;;

		esac

	fi

	# Set the source dir
	# Find dir, depth 0 inside* BUILD TMP, which should only by the SRC_DIR
	SRC_DIR=$(find ${BUILD_TMP}/* -maxdepth 0 -type d)

	# Fail out if SRC_DIR is not found
	if [[ "${SRC_DIR}" == "" ]]; then

		echo -e "\nERROR: cannot find SRC_DIR! Contents of ${BUILD_TMP}: "
		sleep 6s
		ls "${BUILD_TMP}"
		exit 1

	fi


	# Unpack all extra tarballs?
	# example: docker.io (https://packages.debian.org/jessie-backports/docker.io)
	# Awk code, see: https://github.com/ProfessorKaos64/documents/blob/master/awk/tips-and-tricks.md

	if [[ "${UNPACK_ALL}" == "true" ]]; then

		for i in $(ls * | awk -F'[.]' '{print $(NF-1)"."$NF}');
		do

			case * in

				*.tar.bz2)
				tar -xvjf *.tar.bz2 -C "${SRC_DIR}"
				;;

				*.tar.xz)
				tar -xvf *.orig.tar.xz -C "${SRC_DIR}"
				;;

				*.tar.gz)
				tar -xvzf *.orig.tar.gz -C "${SRC_DIR}"
				;;

			esac
		done

	fi

	# If user requested to execute commands before build:
	if [[ "${USER_COMMANDS}" == "true" ]]; then

		cd "${SRC_DIR}"
		echo -e "\n==> Enter commands below (Type quit to stop)\n"

		while [[ "${CMD}" != "quit" && "${CMD}" != "q" ]];
		do
			read -erp "CMD: " CMD

			if [[ "${CMD}" != "quit" &&  "${CMD}" != "q" ]]; then
				${CMD}
			fi

		done

	fi

	# Create our new orig tarball after removing the current one
	# Do this rather than rename, so an xz archive is not renamed as a fake gz archive
	# Reminder: the orig tarball does NOT get a revision number!

	if [[ "${RETRY_BUILD}" == "false" ]]; then

		echo -e "\n==> Creating origninal tarball"
		sleep 2s

		rm -f ${BUILD_TMP}/*.orig.tar.*
		cd ${BUILD_TMP}
		

		# Create tarball
		tar -cvzf "${PKGNAME}_${PKGVER}.orig.tar.gz" $(basename ${SRC_DIR})

	fi

	# Enter source dir
	cd ${SRC_DIR}

	# Last safety check - debian folder
	# If the debian folder is in the original souce, keep it.

	echo -e "\n==> Sanitity checks"

	if [[ ! -d "${SRC_DIR}/debian" ]]; then

		echo -e "\nDebian directory: [FAIL]"

		# no debian folder find and unpack the dget sourced file
		DEBIAN_FOLDER=$(find "${BUILD_TMP}" -type f -name "*.debian.*")

		case "${DEBIAN_FOLDER}" in

			*.tar.xz)
			tar -xvf "${DEBIAN_FOLDER}" -C "${PWD}"
			;;

			*.tar.gz)
			tar -xzvf "${DEBIAN_FOLDER}" -C "${PWD}"
			;;

		esac

	else

		echo -e "\nDebian directory: [OK]"

	fi

	# Remove patches if requested
	if [[ "${PATCH_REMOVE}" == "true" ]]; then

		rm -rf "${SRC_DIR}/debian/patches"

	fi

	# Review debian files
	# Add code to review any debian files, as well as setup.py until "done" entered

	while [[ "${FILE}" != "quit" && "${FILE}" != "q" ]];
	do

		cd ${SRC_DIR}
		echo ""
		ls

		echo -e "\n==> Review packaging files? (Type "quit" when done)\n"
		sleep 0.2s
		read -erp "File: " FILE

		if [[ "${FILE}" != "quit" &&  "${FILE}" != "q" ]]; then
			nano "${FILE}"
		fi

	done

	# update changelog
	# Be sure to include a pacakge revision (e.g. "-1" with "bc_1.0.0+bsos-1") if needed!
	# If a package has an epoch such as "7:ffmpeg_2.7.6-ubuntu", be sure to bump this number 
	# if you already have a package in your repository with a lesser or equal epoch.

	if [[ "${RETRY_BUILD}" == "false" ]]; then

		echo -e "\n==> Updating changelog with dch. Adjust as necessary. Be mindful of epochs!"
		sleep 4s

		# Create basic changelog format if it does exist or update
		if [[ -f "debian/changelog" ]]; then

			dch -p --force-bad-version --force-distribution -v "${PKGVER}${PKGSUFFIX}${PKGREV}" \
			--package "${PKGNAME}" -D $DIST -u "${URGENCY}" "Backported package. No changes made."
			nano "debian/changelog"

		else

			dch -p --force-bad-version --force-distribution --create -v "${PKGVER}${PKGSUFFIX}${PKGREV}" \
			--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Initial upload attempt"

		fi

	fi

}

function_build_package()
{

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Backporting Debian package ${PKGNAME} from source"
	sleep 2s

	# Ask what method

	echo -e "\n==> Use what builder? [pbuilder|dpkg-buildpackage]\n"
	read -erp "Choice: " METHOD


	if [[ "${METHOD}" == "pbuilder" ]]; then

		if ! sudo -E BUILD_TMP=${BUILD_TMP} DIST=${DIST} ARCH=${ARCH} ${BUILDER} \
		${BUILDOPTS}; then

			# back out to SCRIPTDIR
			echo -e "\n!!! FAILED TO BACKPORT. See output!!! \n"
			sleep 5s
			cd "${SCRIPTDIR}" && exit 1

		fi

	elif [[ "${METHOD}" == "dpkg-buildpackage" ]]; then

		# enter dir and attemp to satisfy build deps
		cd ${PKGNAME}*
		if ! sudo mk-build-deps --install --remove; then

			# back out to SCRIPTDIR
			echo -e "\n!!! FAILED TO ACQUIRE BUILD-DEPS. See output!!! \n"
			sleep 5s
			cd "${scritpdir}" && exit 1

		fi

		# Test if we can successfully build the package
		fakeroot debian/rules binary

		# Build a package properly , without GPG signing the package
		dpkg-buildpackage -us -uc

	else

		echo -e "Invalid builder!"
		sleep 4s
		exit 1

	fi

}

main()
{

	# check OS/distro
	if which lsb_release &> /dev/null; then

		OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]' )

	else

		OS=$(cat /etc/os-release | grep -w "NAME" | cut -d'=' -f 2)

	fi

	# set vars
	function_set_vars

	# Setup
	function_setup_env

	# Get source
	function_get_source

	# Backport setup
	function_backport_config

	# Build package
	function_build_package

	# Show summary
	function_show_summary

}

function_show_summary()
{

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

	ls "${BUILD_TMP}" | grep -E "${PKGNAME}"

	# Ask to transfer files if debian binries are built
	# Exit out with log link to reivew if things fail.

	if [[ $(ls "${BUILD_TMP}" | grep -w "deb" | wc -l) -gt 0 ]]; then

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

			fi

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

while :; do
	case $1 in

		--user-commands|-uc)
			# Execute commands before building source package
			export USER_COMMANDS="true"
			EXTRA_OPTS+=("--user-commands")
			;;

		--apt-prefs-hack|-aph)
			# Allow installation of packages newer than Valve's for building purposes
			export DEBIAN_BACKPORTS="true"
			EXTRA_OPTS+=("--apt-prefs-hack")
			;;

		--backports|-bp)
			export DEBIAN_BACKPORTS="true"
			EXTRA_OPTS+=("--backports")
			;;

		--beta-repo|-br)
			# Allow testing/beta repos to be specified
			# See: funcion_set_vars
			if [[ -n "$2" ]]; then
				BETA_REPO=$2
				shift
			else
				echo -e "ERROR: --betarepo|-br requires an argument.\n" >&2
				exit 1
			fi
			;;

		--binary-arch|-ba)
			# Must be added at the end of all arguments, due to how pbuidler final opts
			# are sourced. See "man pbuilder"
			if [[ -n "$2" ]]; then
				echo -e "ERROR: --binary-dep must be the last argument specified." >&2
				exit 1
			else
				BUILDOPTS+=("-- --binary-arch")
			fi
			;;

		--build-stage|-bs)
			if [[ -n "$2" ]]; then
				export DEB_BUILD_PROFILES=$2
				shift
			else
				echo -e "ERROR: --build-stage|-bs requires an argument.\n" >&2
				exit 1
			fi
			;;

		--network|-net)
			# If the package requires use of a network connection
			export USE_NETWORK="yes"
			EXTRA_OPTS+=("--network")
			;;

		--no-clean|-nc)
			# Don't clean before starting pbuilder build
			# Not advised, but at times necessary on systems lacking debhelper packages
			# such as Arch Linux.
			if [[ -n "$2" ]]; then
				echo -e "\nWARNING: It is suggested to have --no-clean|-nc as the last option (before any arch-dep args).\n"
				BUILDOPTS+=("--debbuildopts -nc")
				sleep 3s
			else
				BUILDOPTS+=("--debbuildopts -nc")
			fi
			;;

		--no-test|-nt)
			# do not test after building
			# some packages must be manually configured (e.g. mono)
			export NO_TEST_PKG="true"
			EXTRA_OPTS+=("--no-test")
			;;

		--no-lint|-nl)
			# Skip running linitian
			export NO_LINTIAN="true"
			EXTRA_OPTS+=("--no-lint")
			;;

		--no-unpack|-nu)
			# Don't unpack the source
			# May be useful for building with no patches or dealing with
			# certain builder idiosyncrasies
			export DGET_OPTS="-d"
			EXTRA_OPTS+="--no-unpack"
			;;

		--remove-patches)
			# Dget applies patches (if properly setup), sometimes pbuilder clashes
			# Or, we may want to build without patches
			PATCH_REMOVE="true"
			EXTRA_OPTS+=("--remove-patches")
			;;

		--retry-build|-r)
			# Allow retry of previous build
			# Debian files can still be review
			RETRY_BUILD="true"
			EXTRA_OPTS+=("--retry-build")
			;;

		--testing)
			# send packages to test repo location
			TEST_REPO="true"
			;;

		--unpack-all|-ua)
			# Some packges have archives, such as docker.io, that expect unpacked
			# archive contents in the source dir. dget does not unpack these
			# Attempt to handle these by unpacking them into the source dir.
			export UNPACK_ALL="true"
			EXTRA_OPTS+="--unpack-all"
			;;

		--help|-h)
			cat<<-EOF

			Usage:		./backport-debian-pkg.sh [options]

			Options:
					--apt-prefs-hack	Raemove SteamOS apt preferences lock
					--beta-repo|-br		Enable a beta repo
					--backports|-bp		Utilize LibreGeek Debian backports
					--binary-dep		Builds binary-dependent package
					--network|-net		Enable build-time network connection
					--no-clean|-nc		Build without cleaning ahead of time
					--no-lint|-nl		Disable lintian tests
					--no-test|-nt		Disable pbuilder/sbuild package tests
					--no-unpack|-nu		Don't unpack when using dget
					--remove-patches	Remove any patches from package
					--retry|-r		Retry build. Files are still reviewd
					--testing		Send built package to testing repo
					--help|-h		Display this help text

			Beta repos:
					steamos-tools		SteamOS-Tools beta repo

			EOF
			exit
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

# Set the array BULIDOPTS
BUILDOPTS=$(echo ${BUILDOPTS[@]})
# Set extra opts array
EXTRA_OPTS=$(echo ${EXTRA_OPTS[@]})

# start main
main

# In case the script fails cd back to SCRIPTDIR
cd "${SCRIPTDIR}"
