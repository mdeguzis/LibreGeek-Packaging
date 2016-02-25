#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-NAME.sh
# Script Ver:	0.1.1
# Description:	Attempts to build a deb package from latest PKGNAME
#		github release
#
# See:		GIT URL
#
# Usage:	./build-PKGNAME.sh
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
git_url="GIT_URL"
branch="BRANCH"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
pkgname="PKGNAME"
pkgver="VERSION"
pkgrev="1"
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
	sudo apt-get install -y --force-yes build-essential pkg-config bc

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
	install_prereqs

	# Clone upstream source code and branch
	# NOTE! - If you wish to source versions or commits automatically into variables here,
	# 	  such as commits, of upstream tags, see docs/pkg-versioning.md

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and checkout latest commit
	git clone -b "${branch}" "${git_url}" "${git_dir}"
	
	# add debian files
	cp -r "${scriptdir}/debian" "${git_dir}"
	
	# Remove files that will conflict with what deb helper and debian/* is doing
	rm -f "${git_dir}/Makefile"
	
	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${build_dir}" || exit
	tar -cvzf "${pkgname}-${pkgver}+${pkgsuffix}.orig.tar.gz" "$pkgname"

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -v "${pkgver}+${pkgsuffix}" -M --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	else

		dch --create -v "${pkgver}+${pkgsuffix}" -M --package "${pkgname}" -D "${DIST}" -u "${urgency}"

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
			rsync -arv --exclude-from=$HOME/.config/SteamOS-Tools/repo-exclude.txt ${build_dir}/*${pkgver}* ${USER}@${HOST}:${REPO_FOLDER}
########################################
			# Only move the old changelog if transfer occurs to keep final changelog 
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian"
			
			# If using a fork instead with debiain/ upstream
			cd "${git_dir}" && git add debian/changelog && git commit -m "update changelog" && git push origin "${branch}"
			cd "${scriptdir}"
########################################
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
