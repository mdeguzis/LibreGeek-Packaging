#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	build-yabause.sh
# Script Ver:	0.1.1
# Description:	Attmpts to build a deb package from the latest yabause source
#		code.
#
# See:		https://github.com/Yabause/yabause
#
# Usage:	./build-yabause.sh
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
GIT_URL="https://github.com/Yabause/yabause"
# Try to base this off of the commit where the changelog is updated
branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
# This can be sourced from yabause/yabause/ChangeLog
PKGNAME="yabause"
PKGVER="0.9.15"
PKGREV="1"
# Base version sourced from ZIP file version
PKGSUFFIX="${date_short}git+bsos"
DIST="brewmaster"
URGENCY="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# Need network for pbuilder to pull down ut4 zip
export NETWORK="yes"

# set build directories
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_TMP}/${SRCDIR}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential bc debhelper debhelper cmake pkg-config
	libgl1-mesa-dev libsdl1.2-dev libglib2.0-dev libgtk2.0-dev libgtkglext1-dev libqt4-dev \
	libqt4-opengl-dev libmini18n-dev libopenal-dev dh-autoreconf

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

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and get latest commit tag
	git clone --recursive -b "${branch}" "${GIT_URL}" "${GIT_DIR}"
	cd "${GIT_DIR}"
	LATEST_COMMIT=$(git log -n 1 --pretty=format:"%h")

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_TMP}" || exit
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"

	# Add required files
	cp -r "${scriptdir}/debian" "${GIT_DIR}"

	# enter source dir
	cd "${GIT_DIR}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}" --package "${PKGNAME}" \
		-D "${DIST}" -u "${URGENCY}" "Update to the latest commit ${LATEST_COMMIT}"
		nano "debian/changelog"
	
	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}-${PKGREV}"\
		--package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}" "Update to the latest commit ${LATEST_COMMIT}"
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
	If package was built without 
errors you will see it below.
	If you don't, please check 
build dependency errors listed above.
	
#################################################################
	EOF
	echo -e "Showing contents of: 
${BUILD_TMP}: \n"
	ls "${BUILD_TMP}" | grep -E 
*${PKGVER}*
	# Ask to transfer files if 
debian binries are built
	# Exit out with log link to 
reivew if things fail.
	if [[ $(ls "${BUILD_TMP}" | 
grep *.deb | wc -l) -gt 0 ]]; then
		echo -e "\n==> Would 
you like to transfer any packages that 
were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " 
transfer_choice
		if [[ 
"$transfer_choice" == "y" ]]; then
			# copy files 
to remote server
			rsync -arv 
--info=progress2 -e "ssh -p 
${REMOTE_PORT}" \
			
--filter="merge 
${HOME}/.config/SteamOS-Tools/repo-filter.txt" 
\
			${BUILD_TMP}/ 
${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}
			# uplaod local 
repo changelog
			cp 
"${GIT_DIR}/debian/changelog" 
"${scriptdir}/debian"
		elif [[ 
"$transfer_choice" == "n" ]]; then
			echo -e 
"Upload not requested\n"
		fi
	else
		# Output log file to 
sprunge (pastebin) for review
		echo -e "\n==OH 
NO!==\nIt appears the build has 
failed. See below log file:"
		cat 
${BUILD_TMP}/${PKGNAME}*.build | curl 
-F 'sprunge=<-' http://sprunge.us
	fi
}
# start main
main

