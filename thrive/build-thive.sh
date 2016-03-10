#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-thrive.sh
# Script Ver:	0.1.1
# Description:	Attempts to build a deb package from latest thrive
#		github release
#
# See:		https://github.com/Revolutionary-Games/Thrive
#		https://github.com/Revolutionary-Games/Thrive/blob/master/SetupThrive.sh#L95
#
# Usage:	build-thrive.sh
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

# repo destination vars (use only local hosts!)
USER="mikeyd"
HOST="archboxmtd"

if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

# upstream vars
git_url="https://github.com/Revolutionary-Games/Thrive"
branch="v0.3.1"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="thrive"
pkgver="0.3.1"
upstream_rev="1"
pkgrev="1"
pkgsuffix="bsos${pkgrev}"
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
	sudo apt-get -y --force-yes install autoconf automake build-essential pkg-config bc cmake
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

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone -b "${branch}" "${git_url}" "${git_dir}"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${build_dir}"
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# Add debian files
	cp -r "${scriptdir}/debian" "${git_dir}"

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# Create basic changelog format if it does exist or update
	if [[ -f "debian/changelog" ]]; then

		dch -v "${pkgver}+${pkgsuffix}-${upstream-rev}" --package "${pkgname}" -D $DIST -u "${urgency}" \
		"New release"
		nano "debian/changelog"

	else

		dch --create -v "${pkgver}+${pkgsuffix}-${upstream-rev}" --package "${pkgname}" -D "${DIST}" \
		-u "${urgency}" "New release"
		nano "debian/chanelog"

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
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main

main
