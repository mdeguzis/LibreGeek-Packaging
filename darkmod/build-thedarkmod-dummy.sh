#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt thedarkmod:	build-thedarkmod.sh
# Script Ver:	0.1.1
# Description:	Attempts to build a deb package from the laest "The Dark Mod"
#		release
#
# See:		https://github.com/ProfessorKaos64/thedarkmod
#		http://wiki.thedarkmod.com/index.php?title=The_Dark_Mod_-_Compilation_Guide
#		http://wiki.thedarkmod.com/index.php?title=DarkRadiant_-_Compiling_in_Linux
#
# Usage:	./build-thedarkmod.sh
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
#git_url="https://github.com/ProfessorKaos64/tdm"
#branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH=""
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
# required to run postinstall
USENETWORK="yes"
pkgname="thedarkmod"
pkgver="2.0.3"
pkgrev="7"
upstream_rev="1"
pkgsuffix="git+bsos${pkgrev}"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dirs
export build_dir="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config bc debhelper gcc g++ \
	g++-4.9-multilib m4 zip libglew-dev libglew-dev:i386 libpng12-dev libpng12-dev:i386 \
	libjpeg62-dev libjpeg62-dev:i386 libc6-dev:i386 libxxf86vm-dev libxxf86vm-dev:i386 \
	libopenal-dev libopenal-dev:i386 libasound2-dev libasound2-dev:i386 libxext-dev \
	libxext-dev:i386 scons

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
	# NOTE! - If you wish to source versions or commits automatically into variables here,
	# 	  such as commits, of upstream tags, see docs/pkg-versioning.md

	echo -e "\n==> Obtaining upstream source code\n"

	######## Use a virtual package for now ########
	mkdir -p "${git_dir}"

	# clone and checkout latest commit
	#git clone -b "${branch}" "${git_url}" "${git_dir}"

	# trim .git since this is a larger repo
	#rm -rf "${git_dir}/.git"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${build_dir}" || exit
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# Add debian folder for current virtual package implementation
	cp -r "${scriptdir}/debian-dummy-pkg" "${git_dir}/debian"

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${upstream_rev}" -M --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}-${upstream_rev}" -M --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	USENETWORK=$USENETWORK DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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
	If package was built without errors you will see it below.
	If you don't, please check build dependency errors listed above.
	#################################################################

	EOF

	echo -e "Showing contents of: ${build_dir}: \n"
	ls "${build_dir}" | grep -E *${pkgver}*

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		if [[ -d "${build_dir}" ]]; then

			# copy files to remote server
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}


			# uplaod local repo changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian"

			# If using a fork instead with debiain/ upstream
			#cd "${git_dir}" && git add debian/changelog && git commit -m "update changelog" && git push origin "${branch}"
			#cd "${scriptdir}"

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
