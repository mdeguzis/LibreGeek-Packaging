#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	backport-debian-pkg.sh.sh
# Script Ver:	1.4.1
# Description:	Attempts to build a deb package from backported stretch package
#
# See:		https://github.com/rust-lang/rust
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


if [[ "${arg1}" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

if [[ "${final_opts}" == "--beta-repo" ]]; then

	BETA_REPO="true"

else

	BETA_REPO="false"

fi

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="${ARCH}"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="${BETA_REPO}"
pkgname="$PKGNAME"
pkgver="$PKGVER"
upstream_rev="1"
pkgrev="1"
pkgsuffix="bpo8+bsos${pkgrev}"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build dirs
src_dir="${pkgname}-${pkgver}"
git_dir="${BUILD_DIR}/${src_dir}"

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

	# Set build opts vars based on the above
	if [[ "${DIST}" == "brewmaster" ]]; then

		pkgsuffix="bsos"

	elif [[ "${DIST}" == "jessie" ]]; then

		pkgsuffix="bpo8"

	fi	

	# create BUILD_DIR
	if [[ -d "${BUILD_DIR}" ]]; then

		sudo rm -rf "${BUILD_DIR}"
		mkdir -p "${BUILD_DIR}"

	else

		mkdir -p "${BUILD_DIR}"

	fi

	# enter build dir
	cd "${BUILD_DIR}" || exit

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" && "${BUILDER}" != "pbuilder" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# Obtain all necessary vias via dget
	dget "${DSC}"
	
	# Get filename only from DSC URL
	DSC_FILENAME=$(basename "${DSC}")
	
	# update changelog
	# Be sure to include a pacakge revision (e.g. "-1" with "bc_1.0.0+bsos-1") if needed!
	echo -e "\n==> Updating changelog with dch. Adjust as necessary"
	sleep 2s
	
	cd ${PKGNAME}* || exit
	
	# Create basic changelog format if it does exist or update
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" \
		--package "${pkgname}" -D $DIST -u "${urgency}" "Backported package. No changes made."
		nano "debian/changelog"

	else

		dch -p --force-distribution --create -v "${pkgver}+${pkgsuffix}-${pkgrev}" \
		--package "${pkgname}" -D "${DIST}" -u "${urgency}" "Initial upload attempt"

	fi
	
	# rename original tarball with what dch generates from chagnelog update
	# Remove dash for formatting
	TARBALL_RENAME=$(basename `find .. -maxdepth 1 -type d | grep ${PKGNAME}` | sed 's/-/_/')
	mv ../*.orig.tar.gz ../${TARBALL_RENAME}.orig.tar.gz
	
	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Backporting Debian package ${pkgname} from source"
	sleep 2s

	# Ask what method
	
	echo -e "\n==> Use what method? [pbuilder|local]"
	read -erp "Choice: " METHOD

	if [[ "${METHOD}" == "pbuilder" ]]; then

		if ! sudo -E BUILD_DIR=${BUILD_DIR} DIST=${DIST} ARCH=${ARCH} ${BUILDER} \
		${BUILDOPTS}; then

			# back out to scriptdir
			echo -e "\n!!! FAILED TO BACKPORT. See output!!! \n"
			cd "${scritpdir}"

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

	rm -f ${DSC_FILENAME}

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

	ls "${BUILD_DIR}" | grep -E "${pkgver}" 

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
