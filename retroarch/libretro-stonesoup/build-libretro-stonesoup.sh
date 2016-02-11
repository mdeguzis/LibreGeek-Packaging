#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-libretro-stonesoup.sh
# Script Ver:	1.0.0
# Description:	Attempts to builad a deb package from latest libretro stonesoup
#		github release
#
# See:		https://github.com/meancoot/stonesoup-libretro
#
# Usage:	build-libretro-stonesoup.sh
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
git_url="https://github.com/meancoot/stonesoup-libretro"
branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="libretro-stonesoup"
pkgver="0.15"
pkgrev="1"
pkgsuffix="git+bsos${pkgrev}"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dir
build_dir="$HOME/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get -y --force-yes install build-essential pkg-config bc
}

main()
{

	# create build_dir
	if [[ -d "$build_dir" ]]; then

		sudo rm -rf "$build_dir"
		mkdir -p "$build_dir"

	else

		mkdir -p "$build_dir"

	fi

	# enter build dir
	cd "$build_dir" || exit

	# install prereqs for build
	install_prereqs

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	# clone
	#git clone --recursive -b "$branch" "$git_url" "$git_dir"

	# The git source is very old (2014), source latest PPA source code
	# from libretro PPA unstable repo
	wget https://launchpad.net/~libretro/+archive/ubuntu/testing/+files/libretro-stonesoup_0.15.2%2Br3%7E1%7Eubuntu15.04.1.tar.xz
	tar -xf libretro-stonesoup_0.15.2+r3~1~ubuntu15.04.1.tar.xz
	rm -rf *.tar.xz
	mv libretro-stonesoup* libretro-stonesoup
	rm -rf "debian/bzr-manifest"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${pkgname}"

	# copy in debian folder
	# cp -r $scriptdir/debian "${git_dir}"

	# enter source dir
	cd "${pkgname}"

	# Create basic changelog format
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname (${pkgver}+${pkgsuffix}) $dist_rel; urgency=low

	  * Packaged deb for SteamOS-Tools
	  * See: packages.libregeek.org
	  * Upstream authors and source: $git_url

	 -- $uploader  $date_long

	EOF

	# Perform a little trickery to update existing changelog or create
	# basic file
	cat 'changelog.in' | cat - debian/changelog > temp && mv temp debian/changelog

	# open debian/changelog and update
	echo -e "\n==> Opening changelog for confirmation/changes."
	sleep 3s
	nano debian/changelog

 	# cleanup old files
 	rm -f changelog.in
 	rm -f debian/changelog.in

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	debuild

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
	if [[ "$scriptdir" != "" ]]; then
		cd "$scriptdir" || exit
	else
		cd "$HOME" || exit
	fi
	
	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	echo -e "Showing contents of: ${build_dir}: \n"
	ls "${build_dir}" | grep -E *${pkgver}*

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv --exclude-from=$HOME/.config/SteamOS-Tools/repo-exclude.txt ${build_dir}/*${pkgver}* ${USER}@${HOST}:${REPO_FOLDER}
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
