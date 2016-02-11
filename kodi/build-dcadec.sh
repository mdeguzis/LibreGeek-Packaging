#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-dcadec.sh
# Script Ver:	1.0.1
# Description:	Attempts to build a deb package dcadec git source
#
# See:		https://github.com/graeme-hill/crossguid
# Usage:	build-dcadec.sh
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
git_url="https://github.com/foo86/dcadec"
git_branch="master"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="dcadec"
pkgver="${date_short}"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dir
build_dir="$HOME/build-${pkgname}-temp"
git_dir="${build_dir}/${pkgname}"

install_prereqs()
{

	echo -e "\n==> Installing prerequisites for building...\n"
	sleep 2s
	# install basic build packages
	sudo apt-get install -y --force-yes build-essential pkg-config checkinstall bc \
	debhelper 
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

	# clone and checkout desired commit
	git clone -b "$git_branch" "$git_url" "${git_dir}"
	cd "${git_dir}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")
	git checkout $latest_commit 1> /dev/null

	# Alter pkg suffix based on commit
	pkgsuffix="${latest_commit}git+bsos${pkgrev}"
	
	# Add debian files
        cp -r "$scriptdir/$pkgname/debian" "${git_dir}"

	#################################################
	# Build platform
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	cd ${build_dir}
	tar -cvzf "${pkgname}_${pkgver}.orig.tar.gz" "${pkgname}"

	# emter source dir
	cd "${pkgname}"

	# Create basic changelog
	# This addons build cannot have a revision
	cat <<-EOF> changelog.in
	$pkgname (${pkgver}+${pkgsuffix}) $dist_rel; urgency=low

	  * Packaged deb for SteamOS-Tools
	  * See: packages.libregeek.org
	  * Upstream authors and source: $git_url

	 -- $uploader  $date_long

	EOF

	# Perform a little trickery to update existing changelog or create basic file
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
		ls "${build_dir}" | grep -E *${pkgver}*

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -ep "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# transfer files
			if [[ -d "${build_dir}" ]]; then
				scp ${build_dir}/*${pkgver}* ${USER}@${HOST}:${REPO_FOLDER}
				
				# keep changelog rolling since we maintain the debian folder
				cp "${git_dir}/debian/changelog" "${scriptdir}/${pkgname}/debian"

			fi

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	fi

}

# start main
main
