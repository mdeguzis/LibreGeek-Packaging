#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-npm-package.sh
# Script Ver:	0.1.1
# Description:	Builds simple Debian package from npm module and uploads to 
#		GitHub
#
# See:		https://www.npmjs.com/package/npm-package-search
# See:		https://wiki.debian.org/Javascript/Nodejs/Npm2Deb
#
# Usage:	./build-npm-package.sh [npm_module]
#-------------------------------------------------------------------------------

npm_pkg_name="$1"
scriptdir=$(pwd)
time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
pkgname="npm-${npm_pkg_name}"
upstream_rev="1"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# upstream vars
branch="master"
GIT_USERNAME="ProfessorKaos64"
git_url="https://github.com/${GIT_USERNAME}/${pkgname}"

# set build_dir
npm_temp_dir="$HOME/npm-${pkgname}-temp"
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
	sudo apt-get install -y --force-yes build-essential bc debhelper npm npm2deb

}

main()
{

	# create build_dir
	if [[ -d "$build_dir" ]]; then

		sudo rm -rf "$build_dir"
		sudo rm -rf "$npm_temp_dir"
		mkdir -p "$build_dir"
		mkdir -p "$npm_temp_dir"

	else

		mkdir -p "$build_dir"
		mkdir -p "$npm_temp_dir"

	fi

	# enter build dir
	cd "${npm_temp_dir}" || exit

	# install prereqs for build
	install_prereqs
	
	#################################################
	# Search and validate
	#################################################
	
	echo -e "\n==> Check for existance of : ${npm_pkg_name}?"
	echo -e "    (building local index takes time!)\n"
	sleep 0.5s
	
	read -erp "Choice [y/n]: " search_npm
	
	if [[ "$npm_exists" == "y" ]]; then
	
		# search
		npm search ${npm_pkg_name}
	
	fi

	echo -e "\n==> Please review the dependencies for package: ${npm_pkg_name}\n"
	sleep 3s
	
	npm2deb depends -b -r ${npm_pkg_name}

	echo -e "\n==> Check if someone else has already started working on this module...\n"
	sleep 2s
	
	npm2deb search bower
	
	#################################################
	# Create package files
	#################################################
	
	echo -e "\n==> Has anyone started packaging this module?\n"
	sleep 1s
	
	read -erp "Choice [y/n]: " npm_exists
	
	if [[ "$npm_exists" == "n" ]]; then
	
		# create
		npm2deb create ${npm_pkg_name}
	
	else
	
		# view module
		npm2deb view ${npm_pkg_name}
	
	fi
	
	#################################################
	# Sync files to github repository
	#################################################
	
	# create repository if it does not exist
	cd $HOME
	
	git_missing=$(curl -s https://api.github.com/repos/${GIT_USERNAME}/${npm_pkg_name} | grep "Not Found")
	
	if [[ "$git_missing" != "" ]]; then
	
		# create repo using git api
		curl -u "${GIT_USERNAME}" https://api.github.com/user/repos -d '{"name":"${npm_pkg_name}"}'
		
		# Remember replace USER with your username and REPO with your repository/application name!
		git remote add origin git@github.com:${GIT_USERNAME}/${npm_pkg_name}.git
		git push origin master
		
	else
	
		# check for dir in $HOME, clone if not there
		if [[ -d "$HOME/${npm_pkg_name}" ]]; then
		
			 cd "$HOME/${npm_pkg_name}" || exit
			 
		else
		
			echo -e "repository not found at $HOME location, cloning..."
			cd || exit 
			git clone "${git_url}" "${npm_pkg_name}"
			cd "${npm_pkg_name}" || exit
		
		fi
	
		# Add Debianized files to repo
		cp -r ${build_dir}/${npm_pkg_name}/* .
		
		# correct and update resultant files pushed by npm2deb
		nano debian/node-${npm_pkg_name}/changelog
		nano debian/node-${npm_pkg_name}/debian/control
		nano debian/node-${npm_pkg_name}/debian/copyright
		nano debian/node-${npm_pkg_name}/watch
		
		# Furture TODO? Monitor debian/watch for new package
		# 'uscan --download-current-verion'
	
		# push changes
		git add .
		git commit -m "update source code from npm2deb"
		git push origin $branch
		cp $scriptdir

	fi
	
	#################################################
	# Gather new source files
	#################################################
	
	# clone
	cd "${build_dir}"
	git clone -b "$branch" "$git_url" "$git_dir"

	#################################################
	# Build package
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create the tarball from latest tarball creation script
	# use latest revision designated at the top of this script

	# create source tarball
	tar -cvzf "${pkgname}_${pkgver}.${pkgsuffix}.orig.tar.gz" "${pkgname}"

	# Enter git dir to build
	cd "${git_dir}"

	# Create new changelog if we are not doing an autobuild
	# alter here based on unstable

	cat <<-EOF> changelog.in
	$pkgname (${pkgver}.${pkgsuffix}-${upstream_rev}) $dist_rel; urgency=low

	  * Pacakged deb for SteamOS-Tools
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

	dpkg-buildpackage -rfakeroot -us -uc -sa

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
			mv "${git_dir}/debian/changelog" "$scriptdir/debian-unstable/"

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi
	fi

}

# start main
main
