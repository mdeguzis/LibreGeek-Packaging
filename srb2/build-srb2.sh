#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-srb2.sh
# Script Ver:	1.0.8
# Description:	Attmpts to builad a deb package from latest Sonic Robo Blast 2
#		github release
#
# See:		https://github.com/STJr/SRB2
# See:    https://github.com/STJr/SRB2/issues/45
#
# Usage:	./build-srb2.sh [opts]
# Opts:		[--build-data]
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

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming"
	
fi

# upstream vars
# build from specific commit for stability
#GIT_URL="https://github.com/STJr/SRB2"
GIT_URL="https://github.com/ProfessorKaos64/SRB2"
rel_TARGET="brewmaster"
commit="5c09c31"

# package vars
DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="srb2"
PKGVER="2.1.14"
upstream_rev="1"
PKGREV="1"
DIST="brewmaster"
URGENCY="low"
UPLOADER="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
MAINTAINER="ProfessorKaos64"

# set BUILD_TMP
export BUILD_TMP="${HOME}/build-${PKGNAME}-tmp"
SRCDIR="${PKGNAME}-${PKGVER}"
GIT_DIR="${BUILD_TMP}/${SRCDIR}"

install_prereqs()
{
	clear

	if [[ "$arg1"  == '--build-data' ]]; then
		echo -e "==INFO==\nBuilding both main data package and data pacakge\n"
	fi

	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc debhelper \
	libpng12-dev libglu1-mesa-dev libgl1-mesa-dev nasm:i386 libsdl2-dev libsdl2-mixer-dev \
	libgme-dev

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


	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone (use recursive to get the assets folder)
	git clone -b "$rel_TARGET" "$GIT_URL" "$GIT_DIR"

	# get suffix from TARGET commit (stable TARGETs for now)
	cd "${GIT_DIR}"
	#git checkout $commit 1> /dev/null
	commit=$(git log -n 1 --pretty=format:"%h")
	PKGSUFFIX="git${commit}+bsos${PKGREV}"

	# copy in modified files until fixed upstream
	# cp "$SCRIPTDIR/rules" "${GIT_DIR}/debian"

	#################################################
	# Prepare package (main)
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# enter build dir to package attmpt
	cd "${BUILD_TMP}"

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# Trim .git folders
	find "${GIT_DIR}" -name ".git" -type d -exec sudo rm -r {} \;

	# create source tarball
	tar -cvzf "${PKGNAME}_${PKGVER}+${PKGSUFFIX}.orig.tar.gz" "${SRCDIR}"

	# enter source dir
	cd "${SRCDIR}"


	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}"

	fi


 	#################################################
	# Build Debian package (main)
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	#  build
	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	#################################################
	# Prepare Debian package (data) - if needed
	#################################################

	if [[ "$arg1" == "--build-data" ]]; then

		# now we need to build the data package
		# Pkg ver is independent* of the version of srb2
		# See: https://github.com/STJr/SRB2/issues/45#issuecomment-180838131
		PKGVER_data="2.1.14"
		PKGNAME_data="srb2-data"
		data_dir="assets"

		echo -e "\n==> Building Debian package ${PKGNAME_data} from source\n"
		sleep 2s

		# enter build dir to package attmpt
		cd "${GIT_DIR}"

		# create the tarball from latest tarball creation script
		# use latest revision designated at the top of this script

	# Trim .git folders
	find "${GIT_DIR}" -name ".git" -type d -exec sudo rm -r {} \;

		# create source tarball
		tar -cvzf "${PKGNAME_data}_${PKGVER_data}.orig.tar.gz" "${data_dir}"

		# enter source dir
		cd "${data_dir}"

		# Create basic changelog format

		cat <<-EOF> changelog.in
		$PKGNAME_data (${PKGVER_data}) $DIST; URGENCY=low

		  * Packaged deb for SteamOS-Tools
		  * See: packages.libregeek.org
		  * Upstream authors and source: $GIT_URL

		 -- $UPLOADER  $DATE_LONG

		EOF

		# Perform a little trickery to update existing changelog or create
		# basic file
		cat 'changelog.in' | cat - debian/changelog > tmp && mv temp debian/changelog

		# open debian/changelog and update
		echo -e "\n==> Opening changelog for confirmation/changes."
		sleep 3s
		nano "debian/changelog"

	echo -e "\n==> Updating changelog"
	sleep 2s

	 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}"

	else

		dch -p --create --force-distribution -v "${PKGVER}+${PKGSUFFIX}" --package "${PKGNAME}" -D "${DIST}" -u "${URGENCY}"

	fi


		#################################################
		# Build Debian package (data)
		#################################################

		echo -e "\n==> Building Debian package ${PKGNAME_data} from source\n"
		sleep 2s

		#  build
		DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

		# Move packages to build dir
		mv ${GIT_DIR}/*${PKGVER_data}* "${BUILD_TMP}"

	# end build data run
	fi

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
			cp "${GIT_DIR}/debian/changelog" "${SCRIPTDIR}/debian"

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

