#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-libretro-quicknes.sh
# Script Ver:	1.0.0
# Description:	Attempts to builad a deb package from latest libretro quicknes
#		github release
#
# See:		https://github.com/libretro/QuickNES_Core
#
# Usage:	build-libretro-quicknes.sh
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

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# upstream vars
git_url="https://github.com/libretro/QuickNES_Core"
branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="libretro-quicknes"
pkgver="1"
pkgrev="3"
pkgsuffix="git+bsos${pkgrev}"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set BUILD_DIR
export BUILD_DIR="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${BUILD_DIR}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc zlib1g-dev

}

main()
{

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
	
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone -b "${branch}" "${git_url}" "${git_dir}"
	cd "${git_dir}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${BUILD_DIR}"
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${src_dir}"

	# copy in debian folder
	cp -r "$scriptdir/debian" "${git_dir}"

	# enter source dir
	cd "${src_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Update to the latest commit ${latest_commit}"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Update to the latest commit ${latest_commit}"
		nano "debian/changelog"

	fi 

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
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
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
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
