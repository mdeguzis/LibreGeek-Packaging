#!/bin/bash

# -------------------------------------------------------------------------------
# Author:    	Michael DeGuzis
# Git:	    	https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-pcsx2-unstable.sh
# Script Ver:	0.9.9
# Description:	Attempts to build a deb package from PCSX2 git source
#		It is highly suggested to build in a 32 bit environment!!!
#		Ref: https://github.com/ProfessorKaos64/RetroRig/pull/85
#
# See:		https://code.google.com/p/pcsx2/wiki/CompilationGuideForLinux
#		https://github.com/PCSX2/pcsx2/wiki/Installing-on-Linux
# Usage:	./build-pcsx2-unstable.sh
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

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
ARCH="i386"
pkgname="pcsx2-unstable"
pkgrev="1"
upstream_rev="1"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# build dirs
export build_dir="/home/desktop/build-${pkgname}-temp"
src_dir="${pkgname}"
git_dir="${build_dir}/${src_dir}"
git_url="https://github.com/PCSX2/pcsx2"
branch="master"

# package vars
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"

install_prereqs()
{

	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install needed packages
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall

	echo -e "\n==> Installing pcsx2 build dependencies...\n"
	sleep 2s

	#############################################################
	# Check for i386 environment, warn user before building
	#############################################################

	arch_check=$(uname -m)
	if [[ "$arch_check" == "i386" ]]; then

		# 32-bit build depedencies required to build on x86_64
		sudo apt-get install -y --force-yes libaio-dev:i386 libasound2-dev:i386 \
		libbz2-dev:i386 libcg:i386 libcggl:i386 libwayland-dev:i386 libegl1-mesa-dev:i386 \
		libgl1-mesa-dev:i386 libglew-dev:i386 libglu1-mesa-dev:i386 libglu1-mesa-dev:i386 \
		libwxgtk3.0-dev:i386 libjpeg62-turbo-dev:i386 libfreetype6-dev:i386 libdirectfb-dev:i386 \
		libglib2.0-dev:i386 libavahi-client-dev:i386 libpulse-dev:i386 libsdl1.2-dev:i386 \
		libsoundtouch-dev:i386 libsparsehash-dev libwxbase3.0-dev:i386 libx11-dev:i386 \
		nvidia-cg-dev:i386 nvidia-cg-toolkit portaudio19-dev:i386 zlib1g-dev:i386 \
		libgtk2.0-dev libpng++-dev libsdl2-dev

	elif [[ "$arch_check" == "x86_64" ]]; then

		# 32-bit build depedencies required to build on x86_64
		sudo apt-get install -y --force-yes devscripts build-essential checkinstall \
		cmake debhelper dpkg-dev libaio-dev libasound2-dev libbz2-dev libgl1-mesa-dev \
		libglu1-mesa-dev libgtk2.0-dev libpng12-dev libpng++-dev libpulse-dev libsdl2-dev \
		libsoundtouch-dev libwxbase3.0-dev libwxgtk3.0-dev libx11-dev locales portaudio19-dev zlib1g-dev 

	fi

}

main()
{
	# Note: based on:
	# https://github.com/PCSX2/pcsx2/blob/master/debian-packager/create_built_tarball.sh

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

	# clone and checkout desired commit
        git clone -b "${branch}" "${git_url}" "${git_dir}"
        cd "${git_dir}"
        latest_commit=$(git log -n 1 --pretty=format:"%h")
        git checkout $latest_commit 1> /dev/null

	# get latest base release for changelog
	# This is used because upstream does tend to use release tags
	base_release=$(git describe --abbrev=0 --tags)
	pkgver=$(sed "s|[-|a-z]||g" <<<"$base_release")

        # Alter pkg suffix based on commit
        pkgsuffix="${date_short}git+bsos${pkgrev}"

	#################################################
	# Prepare build (upstream-specific)
	#################################################

	echo -e "\nRemove 3rdparty code"
	rm -fr "$git_dir/3rdparty"
	rm -fr "$git_dir/fps2bios"
	rm -fr "$git_dir/tools"

	echo "Remove non free plugins"
	# remove also deprecated plugins
	for plugin in CDVDiso CDVDisoEFP CDVDlinuz CDVDolio CDVDpeops dev9ghzdrk \
	PeopsSPU2 SSSPSXPAD USBqemu xpad zerogs zerospu2
	do
		rm -fr "$git_dir/plugins/$plugin"
	done

	echo "Remove remaining non free file. TODO UPSTREAM"

	rm -rf $git_dir/unfree
	rm -rf $git_dir/plugins/GSdx/baseclasses
	rm -f  $git_dir/plugins/zzogl-pg/opengl/Win32/aviUtil.h
	rm -f  $git_dir/common/src/Utilities/x86/MemcpyFast.cpp

	# To save 66% of the package size
	rm -rf  $git_dir/.git

	# copy in debian folder
	cp -r "$scriptdir/debian-unstable" "${git_dir}/debian"

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# enter build dir to create tarball
	cd "${build_dir}"

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch --force-distribution -v "${pkgver}+${pkgsuffix}-${upstream_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Update build to latest upstream commit [$latest_commit]"
		nano debian/changelog

	else

		dch --create --force-distribution -v "${pkgver}+${pkgsuffix}-${upstream_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
		"Update build to latest upstream commit [$latest_commit]"
		nano debian/changelog

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	# Due to problems with shared libraries, needs an extra option here besides ARCH
	# See: https://bugs.launchpad.net/ubuntu/+source/pbuilder/+bug/1300726
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

	ls "${build_dir}" | grep -E "${pkgver}" 

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
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian-unstable/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
