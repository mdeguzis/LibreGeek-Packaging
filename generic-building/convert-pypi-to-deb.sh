#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-humblebundle.sh
# Script Ver:	1.9.5
# Description:	Converts a PyPi package to a standard Debian package
#
# Usage:	./convert-pypi-to-deb.sh
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
export STEAMOS_TOOLS_BETA_HOOK="${BETA_REPO}"
PKGNAME="$PKGNAME"
PKGREV="1"
URGENCY="low"

# set build dirs
SRC_DIR="${BUILD_TMP}/${PKGNAME}-${PKGNAME}"

install_prereqs()
{

	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install python-pip python python-stdeb python3-stdeb \
	devscripts

}

function_set_vars()
{

	echo -e "\n==> Setting vars\n"

	echo -e "\nPress ENTER to use last: ${OLD_PKGNAME}"
	read -erp "Target package name: " PKGNAME
	if  [[ "${PKGNAME}" == "" ]]; then PKGNAME="${OLD_PKGNAME}"; fi
	export OLD_PKGNAME="${PKGNAME}"

	# now set the build dir for results
	export BUILD_TMP="${HOME}/build-${PKGNAME}-temp"

	read -erp "Arch target: " ARCH
	if  [[ "${ARCH}" == "" ]]; then ARCH="${OLD_ARCH}"; fi
	export OLD_ARCH="${ARCH}"

	echo -e "\nPress ENTER to use last: ${OLD_DIST}"
	read -erp "Distribution target: " DIST
	if  [[ "${DIST}" == "" ]]; then DIST="${OLD_DIST}"; fi
	export OLD_DIST="${DIST}"

	echo -e "\nPress ENTER to use last: ${OLD_MAINTAINER}"
	read -erp "Maintainer name: " MAINTAINER
	if  [[ "${MAINTAINER}" == "" ]]; then MAINTAINER="${OLD_MAINTAINER}"; fi
	export OLD_MAINTAINER="${MAINTAINER}"

	echo -e "\nPress ENTER to use last: ${OLD_MAINTAINER_EMAIL}"
	read -erp "Maintainer email: " MAINTAINER_EMAIL
	if  [[ "${MAINTAINER_EMAIL}" == "" ]]; then DIST="${OLD_MAINTAINER_EMAIL}"; fi
	export OLD_MAINTAINER_EMAIL="${MAINTAINER_EMAIL}"

	# Set projet folder name for uploading built packages

	if [[ "${DIST}" == "brewmaster" ]]; then PROJECT_FOLDER="steamos-tools"; fi
	if [[ "${DIST}" == "jessie" ]]; then PROJECT_FOLDER="debian"; fi
	if [[ "${DIST}" == "jessie-backports" ]]; then PROJECT_FOLDER="debian"; fi

	# Set repo folder destination
	REPO_FOLDER="/home/mikeyd/packaging/${PROJECT_FOLDER}/incoming"

}

main()
{

	# Set package vars
	function_set_vars

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
	install_prereqs
	
	#################################################
	# Search and validate
	#################################################

	# Review options first in case things are not what the user wants

	cat<<-EOF

	============================
	Please review
	============================

	PyPi package: ${PKGNAME}
	Buidler: ${BUILDER}
	Distribution: ${DIST}
	ARCH: ${ARCH}
	Builder options: ${BUILDOPTS}
	Repo folder: ${REPO_FOLDER}

	Press any key to continue
	EOF

	read -erp "" FAKE_ENTER_KEY

	echo -e "\n==> Checking for existance of: ${PKGNAME}"
	sleep 0.5s

	# search
	# pip search returns loose results, so grep/awk
	pip search ${PKGNAME} | awk "/${PKGNAME}/"

	echo ""
	read -erp "Continue? [y/n]: " CONTINUE_CHOICE
	sleep 0.5s
	
	if [[ "$CONTINUE_CHOICE" != "y" ]]; then
		exit 1
	fi
	
	#################################################
	# Fetch source
	#################################################
	
	if ! pypi-download  ${PKGNAME}; then

		echo -e "\nERROR: Package download failed!\n"
		exit 1
	
	fi
	
	#################################################
	# Prepare source
	#################################################
	
	# Rename 
	# mv *.tar.gz "${PKGNAME}_${PKGVER}${DIST_CODE}.orig.tar.gz"
	
	# crete deb files
	py2dsc *.tar.gz

	# Set SRC_DIR
	SRC_DIR=$(find "${PWD}" -type d -name "${PKGNAME}*")
	
	##############################
	# Alter Debian packaging files
	##############################
	
	echo -e "\n==> Modifying Debian package files"
	sleep 2s

	# remove garbage autogen files
	find ${SRC_DIR} -name changelog -exec rm -fv '{}' \;

	# control
	sed -i "s|Maintainer*|Maintainer: ${MAINTAINER} \<$MAINTAINER_EMAIL}\>|g" "${SRC_DIR}/debian/control"

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v -D "${DIST}" -u "${URGENCY}" "Update release"

	else

		dch -p --create --force-distribution -D "${DIST}" -u "${URGENCY}" "Initial build"

	fi
	
	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${PKGNAME} from source\n"
	sleep 2s

	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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
		read -erp "Chohumblebundle: " TRANSFER_CHOICE

		if [[ "${TRANSFER_CHOICE}" == "y" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_TMP}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# uplaod local repo changelog
			cp "${SRC_DIR}/debian/changelog" "${SCRIPTDIR}/debian"

		elif [[ "${TRANSFER_CHOICE}" == "n" ]]; then
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
