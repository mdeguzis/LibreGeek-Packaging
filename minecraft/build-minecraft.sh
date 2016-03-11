#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-minecraft.sh
# Script Ver:	1.0.0
# Description:	Attempts to build a deb package from latest Minecraft jar
#		file release
#
# See:		https://s3.amazonaws.com/Minecraft.Download/launcher/Minecraft.jar
#
# Usage:	./build-minecraft.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=$(date +"%T")

# repo destination vars (use only local hosts!)
USER="mikeyd"
HOST="archboxmtd"

if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# upstream vars
git_url=""
branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="minecraft"
pkgver="1.9"
pkgrev="2"
upstream_rev="1"
pkgsuffix="bsos${pkgrev}"
BUILDER="pdebuild"
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
	sudo apt-get install -y --force-yes build-essential debhelper bc openjdk-7-jre

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
	#git clone -b "$branch" "$git_url" "$git_dir"

	# Create empty git dir to just store debian/ files
	mkdir -p "${git_dir}"

	# Get jar file
	curl -o "${git_dir}/Minecraft.jar" "https://s3.amazonaws.com/Minecraft.Download/launcher/Minecraft.jar" -#
	
	# Inject other files from scriptdir
	cp "${scriptdir}/minecraft.png" "${git_dir}"
	cp "${scriptdir}/minecraft-launcher.sh" "${git_dir}/minecraft"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# copy in debian folder
	cp -r "${scriptdir}/debian" "${git_dir}"

	# enter source dir
	cd "${src_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -v --force-distribution "${pkgver}+${pkgsuffix}-${upstream_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

	else

		dch --create -v --force-distribution "${pkgver}+${pkgsuffix}-${upstream_rev}" --package "${pkgname}" -D "${DIST}" -u "${urgency}"

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

	
	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)
	
	# back out of build temp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "${scriptdir}" || exit
	else
		cd "${HOME}" || exit
	fi
	
	# inform user of packages
	cat<<- EOF 
	#################################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependency errors listed above.
	#################################################################

	EOF

	echo -e "Showing contents of: ${build_dir}: \n"
	ls "${build_dir}" | grep $pkgver

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		if [[ -d "${build_dir}" ]]; then

			# copy files to remote server
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

			# Only move the old changelog if transfer occurs to keep final changelog 
			# out of the picture until a confirmed build is made. Remove if upstream has their own.
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian"

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main and log to tmp
main | tee "/tmp/${pkgname}-build-log-temp.txt"

# convert log file to Unix compatible ASCII
strings "/tmp/${pkgname}-build-log-temp.txt" > "/tmp/${pkgname}-build-log.txt"

# strings does catch all characters that I could 
# work with, final cleanup
sed -i 's|\[J||g' "/tmp/${pkgname}-build-log.txt"

# remove file not needed anymore
rm -f "/tmp/${pkgname}-build-log-temp.txt"
