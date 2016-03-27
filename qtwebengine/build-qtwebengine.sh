#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-qtwebengine.sh
# Script Ver:	1.0.0
# Description:	Builds package of QT 5.6.0 "qtwebengine"
#
# See:		http://code.qt.io/cgit/qt/qtwebengine.git/
#
# Usage:	build-qtwebengine.sh
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
git_url="https://code.qt.io/qt/qtwebengine.git"
branch="v5.6.0"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="false"
#pkgname="qt"
pkgname="qtbase-opensource-src"
pkgver="5.6.0"
pkgrev="1"
pkgsuffix="git+bsos"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dir
export build_dir="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get install bison build-essential gperf flex ruby python libasound2-dev libbz2-dev libcap-dev \
	libcups2-dev libdrm-dev libegl1-mesa-dev libgcrypt11-dev libnss3-dev libpci-dev libpulse-dev libudev-dev \
	libxtst-dev gyp ninja

}

main()
{

	# create build_dir
	if [[ -d "${build_dir}" ]]; then

		sudo rm -rf "${build_dir}"
		mkdir -p "${build_dir}"

	else

		mkdir -p "${build_dir}"

	fi


	# enter build dir
	cd "${build_dir}" || exit

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	else

		# required for dh_clean
		sudo apt-get install -y --force-yes pkg-kde-tools

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone -b "${branch}" "${git_url}" "${git_dir}"

	# trim git
	# rm -rf "${git_dir}/.git"

	#################################################
	# Prep source
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${build_dir}"
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# Try using upstream Sid debian/ ?

	# rm -rf "${git_dir}/debian"
	# cp -r "${scriptdir}/debian" "${git_dir}"

	###############################################################
	# build package
	###############################################################

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Update release"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Initial upload"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

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

	Showing contents of: ${build_dir}

	EOF

	ls "${build_dir}" | grep -E "${pkgver}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
