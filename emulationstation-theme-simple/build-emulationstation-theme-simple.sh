#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-emulationstation-theme-simple.sh
# Script Ver:	1.0.0
# Description:	Attmpts to builad a deb package from latest emulationstation
#		github release
#
# See:		https://github.com/RetroPie/es-theme-simple
#
# Usage:	build-emulationstation-theme-simple.sh
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
GIT_URL="https://github.com/RetroPie/es-theme-simple"
branch="master"
commit="e9c72a3"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="emulationstation-theme-simple"
PKGVER="1.4"
upstream_rev="1"
PKGREV="1"
PKGSUFFIX="${commit}+git+bsos${PKGREV}"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

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
	sudo apt-get -y --force-yes install build-essential pkg-config bc \
	debhelper rsync


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

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and checkout commit
	git clone -b "$branch" "$GIT_URL" "$GIT_DIR"
	cd "$GIT_DIR" && git checkout "$commit"
	
	# copy in debian folder
	cp -r "$scriptdir/debian" "${GIT_DIR}"
	
	# enter build dir
	cd "${BUILD_TMP}" || exit

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${PKGNAME}_${PKGVER}.orig.tar.gz" "${SRCDIR}"

	# copy in debian folder
	cp -r "$scriptdir/debian" "${GIT_DIR}"

	# enter source dir
	cd "${SRCDIR}"


	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${urgency}"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${urgency}"

	fi


	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	#  build
	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	#################################################
	# Post install configuration
	#################################################
	
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
	
	# back out of build tmp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "${scriptdir}" || exit
	else
		cd "${HOME}" || exit
	fi
	
	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	echo -e "Showing contents of: ${BUILD_TMP}: \n"
	ls "${BUILD_TMP}" | grep $PKGNAME_$PKGVER

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_TMP}" ]]; then
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			
			# Only move the old changelog if transfer occurs to keep final changelog 
			# out of the picture until a confirmed build is made. Remove if upstream has their own.
			cp "${GIT_DIR}/debian/changelog" "${scriptdir}/debian"

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
