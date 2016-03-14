#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-dolphin-emu-master.sh
# Script Ver:	1.0.0
# Description:	Attempts to build a deb package from latest dolphin-emu
#		github release (master tree)
#
# See:		https://github.com/dolphin-emu/dolphin/
#
# Usage:	build-dolphin-emu-master.sh
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
git_url="https://github.com/dolphin-emu/dolphin/"
rel_target="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="dolphin-emu"
pkgver="4.0"
pkgrev="1"
pkgsuffix="git+bsos${pkgrev}"
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

	echo -e "\n==> Installing $pkgname build dependencies...\n"
	sleep 2s

	sudo apt-get install -y --force-yes debhelper cmake pkg-config lsb-release libao-dev libasound2-dev \
	libavcodec-dev libavformat-dev libbluetooth-dev libenet-dev libevdev-dev libgtk2.0-dev liblzo2-dev \
	libminiupnpc-dev libopenal-dev libpolarssl-dev libpulse-dev libreadline-dev libsdl2-dev libsfml-dev \
	libsoil-dev libswscale-dev libudev-dev libusb-1.0-0-dev libwxbase3.0-dev libwxgtk3.0-dev libxext-dev \
	libxrandr-dev portaudio19-dev zlib1g-dev

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

		# need cdbs before build for dh_clean
		sudo apt-get install -y --force-yes cdbs

	fi


	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	git clone -b "${rel_target}" "${git_url}" "${git_dir}"

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${src_dir}"

	# copy in debian folder
	cp -r "$scriptdir/debian-master" "${git_dir}/debian"

	# enter source dir
	cd "${src_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${upsteam_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Initial upload / build attempt"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}-${upsteam_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Initial upload / build attemp"
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

	Showing contents of: ${build_dir}

	EOF

	ls "${build_dir}" | grep ${pkgver}

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
