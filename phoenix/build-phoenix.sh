#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-phoenix.sh
# Script Ver:	1.0.0
# Description:	Builds simple pacakge for Phoenix (Libretro front-end)
#
# See:		https://github.com/team-phoenix/Phoenix
#		https://github.com/team-phoenix/Phoenix/wiki/Dependencies
#		https://github.com/team-phoenix/Phoenix/wiki/Building
#
# Usage:	./build-phoenix-steamos.sh [option]
# Options:	--build-test
#-------------------------------------------------------------------------------

arg1="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

# upstream vars
git_url="https://github.com/team-phoenix/Phoenix"
rel_target="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="phoenix"
pkgver="0.0.0"
upstream_rev="1"
pkgrev="1"
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

	# Avoid libattr garbage for 32 bit package installed by emulators
	if [[ -f "/usr/share/doc/libattr1/changelog.Debian.gz" ]]; then

		sudo mv "/usr/share/doc/libattr1/changelog.Debian.gz" \
		"/usr/share/doc/libattr1/changelog.Debian.gz.old" 2> /dev/null
	fi

	# install basic build packages
	sudo apt-get install -y --force-yes build-essential git mesa-common-dev libglu1-mesa-dev \
	libsdl2-dev libsamplerate0-dev

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

	echo -e "\n==> Obtaining upstream source code\n"

	# clone and checkout desired commit
	git clone --recursive -b "$rel_target" "$git_url" "${git_dir}"
	
	# copy in debian folder
	cp "$scriptdir/debian" "${git_dir}"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${pkgname}"

	# Enter git dir to build
	cd "${git_dir}"
	
	# Get commit for version
	latest_commit=$(git log -n 1 --pretty=format:"%h")
	pkgsuffix="git${latest_commit}+bsos${pkgrev}"

	# Create new changelog if we are not doing an autobuild
	# alter here based on unstable

	cat <<-EOF> changelog.in
	$pkgname (${pkgver}+${pkgsuffix}-${upstream_rev}) $dist_rel; urgency=low

	  * Build attempt $pkgrev
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

	#dpkg-buildpackage -rfakeroot -us -uc -sa

	# PKG TESTING ONLY FOR NOW
	if [[ "$arg1" == "--build-test" ]]; then

		mkdir Phoenix-build
		cd Phoenix-build
		qmake ../Phoenix -r
		make -j8
		cd debug && ls

	fi

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
	ls ${build_dir}| grep ${pkgver}

	if [[ "$autobuild" != "yes" ]]; then

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -erp "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# transfer packages
			scp ${build_dir}/*${pkgver}* mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

			# Preserve changelog
			cd "${git_dir}" && git add debian/changelog
			git commit -m "update changelog" && git push origin master
			cd "$scriptdir" 

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi
	fi

}

# start main
main
