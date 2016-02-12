#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-playonlinux-unstable.sh
# Script Ver:	0.1.1
# Description:	Attempts to build a deb package from latest PlayOnLinux 4
#		github release
#
# See:		https://github.com/PlayOnLinux/POL-POM-4
#
# Usage:	build-playonlinux-unstable.sh
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
git_url="https://github.com/PlayOnLinux/POL-POM-4"
branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="playonlinux-unstable"
upstream_rev="1"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dirs
build_dir="$HOME/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config bc python imagemagick

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

	# clone and checkout latest commit
	git clone -b "$branch" "$git_url" "${git_dir}"
	cd "${git_dir}"
	
	# get latest base release for changelog 
	# This is used because upstream does tend to use release tags
	pkgver=$(git tag | tail -n 1)
	latest_commit=$(git log -n 1 --pretty=format:"%h")
	git checkout $latest_commit 1> /dev/null

	# Alter pkg suffix based on commit
	pkgsuffix="${latest_commit}git+bsos${pkgrev}"
	
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
	cd "$build_dir" || exit
	tar -cvzf "${pkgname}_${pkgver}.${pkgsuffix}.orig.tar.gz" "${pkgname}"

	# enter source dir
	cd "${git_dir}"

	# Create basic changelog format
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname (${pkgver}.${pkgsuffix}-${upstream_rev}) $dist_rel; urgency=low

	  * New unstable build against upstream commit $latest_commit
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

			# Only move the old changelog if transfer occurs to keep final changelog 
			cd "${git_dir}" && git add debian/changelog && git commit -m "update changelog" && git push origin master

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main

