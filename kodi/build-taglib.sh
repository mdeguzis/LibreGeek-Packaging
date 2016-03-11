#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-taglib.sh
# Script Ver:	1.0.0
# Description:	Attempts to build a deb package taglib git source
#
# See:		https://github.com/taglib/taglib
# Usage:	build-taglib.sh
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

# upstream vars
git_url="https://github.com/taglib/taglib"
git_branch="v1.10"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS=""
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="taglib"
pkgver="1.10"
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

	echo -e "\n==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config checkinstall bc \
	cmake debhelper dpkg-dev zlib1g-dev pkg-kde-tools doxygen graphviz gsfonts-x11 quilt
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

	git clone -b "$git_branch" "$git_url" "$git_dir"

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

        # funnel old changelog.in to changelog or create basic file
        cp -r "$scriptdir/$pkgname/debian" "${git_dir}"

	# emter source dir
	cd "${src_dir}"


	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	else

		dch --create --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

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

	# back out of build temp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "${scriptdir}" || exit
	else
		cd "${HOME}" || exit
	fi

	# If "build_all" is requested, skip user interaction

	if [[ "$build_all" == "yes" ]]; then

		echo -e "\n==INFO==\nAuto-build requested"
		mv ${build_dir}/*.deb "$auto_build_dir"
		sleep 2s

	else

		# inform user of packages
		echo -e "\n############################################################"
		echo -e "If package was built without errors you will see it below."
		echo -e "If you don't, please check build dependcy errors listed above."
		echo -e "############################################################\n"

		echo -e "Showing contents of: ${build_dir}: \n"
		ls "${build_dir}" | grep -E "${pkgver}" "$pkgver"

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# transfer files
			if [[ -d "${build_dir}" ]]; then
			rsync -arv -e 'ssh -p ${REMOTE_PORT}' --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			
				# Only move the old changelog if transfer occurs to keep final changelog
				cp "${git_dir}/debian/changelog" "${scriptdir}/debian"
			
			fi

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	fi

}

# start main
main
