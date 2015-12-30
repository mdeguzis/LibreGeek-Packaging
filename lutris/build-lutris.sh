#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-lutris.sh
# Script Ver:	1.1.1
# Description:	Attempts to build a deb package from latest Lutris
#		github release
#
# See:		https://github.com/lutris/lutris
#
# Usage:	build-snis.sh
#
#-------------------------------------------------------------------------------

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

# upstream vars
git_url="https://github.com/lutris/lutris"
rel_target="v0.3.7.1"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="lutris"
pkgver="0.3.7.1"
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
	sudo apt-get -y --force-yes install autoconf automake build-essential pkg-config bc checkinstall \
	cdbs debhelper python python-support gir1.2-gtk-3.0 gir1.2-glib-2.0 python-gi libgirepository1.0-dev \

	# Not originally stated in the upstream control file, these 32 bit libraries are needed:
	sudo apt-get install -y --force-yes libsdl2-2.0-0:i386

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
	git clone -b "$rel_target" "$git_url" "$git_dir"
	
	# remove .git folder to save space on build
	rm -f "$git_dir/.git"

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${pkgname}"

	# enter source dir
	cd "${pkgname}"

	commits_full=$(git log --pretty=format:"  * %cd %h %s")

	# Create basic changelog format
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname (${pkgver}+${pkgsuffix}) $dist_rel; urgency=low

	  * Packaged deb for SteamOS-Tools
	  * See: packages.libregeek.org
	  * Upstream authors and source: $git_url
	  * Now includes support for the Lutris Kodi Addon
	  * For addon information, see: https://github.com/RobLoach/script.lutris

	 -- $uploader  $date_long

	EOF

	# Append old changelog from script dir
	cat 'changelog.in' | cat - $scriptdir/changelog.old > temp && mv temp debian/changelog.in

	# Perform a little trickery to update existing changelog from upstream
	# If no changelog upstream exists, comment this section out, and change the above line
	cat 'changelog.in' | cat - debian/changelog > temp && mv temp debian/changelog

	# open debian/changelog and update
	echo -e "\n==> Opening changelog for confirmation/changes."
	sleep 3s
	nano debian/changelog

 	# Keep the old changelog so it can be appended next time
 	mv changelog.in $scriptdir/changelog.old

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	dpkg-buildpackage -rfakeroot -us -uc

	#################################################
	# Post install configuration
	#################################################
	
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

		# cut files
		if [[ -d "${build_dir}" ]]; then
			scp ${build_dir}/*${pkgver}* mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
