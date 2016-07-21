#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-llvm-3.8.sh
# Script Ver:	1.0.0
# Description:	Attempts to build a deb package from latest llvm-3.8
#
# Usage:	build-llvm-3.8.sh
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

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/steamos-tools/incoming"

fi

# upstream vars
#git_url="https://github.com/llvm-3.8/dolphin/"
target="5.0"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="false"
PKGNAME="llvm-3.8"
PKGVER="3.8.1"
PKGREV="1"
EPOCH="1"
PKGSUFFIX="git+bsos"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_DIR
export BUILD_DIR="${HOME}/build-${PKGNAME}-temp"
SRC_DIR="${BUILD_DIR}/llvm-3.8-source"

install_prereqs()
{

	echo -e "\n==> Installing $PKGNAME build dependencies...\n"
	sleep 2s

	sudo apt-get install -y --force-yes debhelper 

}

main()
{

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	################################################
	# obtain sources
	#################################################

	# Clone upstream source code and target
	
	echo -e "\n==> Obtaining upstream source code\n"
	mkdir -p "${SRC_DIR}"
	dget -d http://http.debian.net/debian/pool/main/l/llvm-toolchain-3.8/llvm-toolchain-3.8_3.8.1-4.dsc
	
	echo -e "\n==> Extracting original sources\n"
	sleep 2s
	
	# Extact the orig archives into one directory to use for original source
	ORIG_TARBALL_VER="${PKG_NAME}-${FULL_VER}"
	
	for filename in *.tar.bz2
	do
		echo "Extracting ${filename}"
		tar xfj ${filename} -C "${SRC_DIR}"
	done

	# ! TODO ! - once above debian fix verified, submit patch upstream (see: gmail thread)
	
	################################################
	# Prepare sources
	#################################################
	
	# Back out to create the orig. tarball
	cd "${BUILD_DIR}" || exit 1
	
	echo -e "\n==> Creating original tarball\n"
	sleep 2s
	tar -cvzf "${ORIG_TARBALL_VER}.orig.tar.gz" "$(basename ${SRC_DIR})"


	################################################
	# Build package
	#################################################
	
	# Remove cruft
	rm -rf *.xz *.bz2 *.dsc
	
	# enter source dir
	cd "${SRC_DIR}"
	
	echo -e "\n==> Updating changelog"
	sleep 2s
	
	# update changelog with dch
	dch -i

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

	# clean up dirs

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

	ls "${BUILD_DIR}" | grep ${PKGVER}

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${BUILD_DIR}" ]]; then
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${BUILD_DIR}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
