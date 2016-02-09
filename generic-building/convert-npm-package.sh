#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	convert-npm-package.sh
# Script Ver:	0.9.1
# Description:	Builds simple Debian package from npm module and uploads to 
#		GitHub. Creates repo if it doesn't exist.
#
# See:		https://www.npmjs.com/package/npm-package-search
# See:		https://wiki.debian.org/Javascript/Nodejs/Npm2Deb
#
# Usage:	./convert-npm-package.sh [npm_module]
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
description_long="Converted Debain package using npm2deb"

# upstream vars
branch="master"
GIT_USERNAME="ProfessorKaos64"
git_url="https://github.com/${GIT_USERNAME}/${pkgname}"

# set build_dir
npm_temp_dir="$HOME/${pkgname}-temp"

# bail out if not arg
if [[ "$npm_pkg_name" == "" ]]; then
	clear
	echo -e "==ERROR==\nYou must specify and NPM package name as an arugment!\n"
	exit 1
fi

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
	if [[ -d "$npm_temp_dir" ]]; then

		sudo rm -rf "$npm_temp_dir"
		mkdir -p "$npm_temp_dir"

	else

		mkdir -p "$npm_temp_dir"

	fi

	# enter build dir
	cd "${npm_temp_dir}" || exit

	# install prereqs for build
	install_prereqs
	
	#################################################
	# Search and validate
	#################################################
	
	echo -e "\n==> Check for existance of: ${npm_pkg_name}?"
	echo -e "    (building local index takes time!)\n"
	sleep 0.5s
	
	read -erp "Choice [y/n]: " search_npm
	
	if [[ "$npm_exists" == "y" ]]; then
	
		# search
		npm search ${npm_pkg_name}

	fi

	echo -e "\n==> Please review the dependencies for package: ${npm_pkg_name}"
	sleep 2s
	
	echo -e "\nGenerating dependency list, please wait..."
	npm2deb depends -b -r ${npm_pkg_name} &> ${npm_pkg_name}.deps
	less ${npm_pkg_name}.deps
	
	read -erp "Continue? [y/n]: " continue_choice
	sleep 0.5s
	
	if [[ "$continue_choice" != "y" ]]; then
		exit 1
	fi

	echo -e "\n==> Checking if someone else has already started working on this module..."
	sleep 2s
	
	npm2deb search bower
	
	#################################################
	# Create package files
	#################################################
	
	echo -e "==> Has anyone started packaging this module?\n"
	sleep 1s
	
	read -erp "Choice [y/n]: " npm_exists
	
	# Furture TODO? Monitor debian/watch for new package
	# 'uscan --download-current-verion'
	
	if [[ "$npm_exists" == "n" ]]; then
	
		# create
		echo -e "Creating converted files..."
		npm2deb create ${npm_pkg_name}
	
	else
	
		# view module
		echo -e "Assuming y, review output below..."
		npm2deb view ${npm_pkg_name}
		sleep 5s
		exit 1
	
	fi
	
	#################################################
	# Create/sync files to github repository
	#################################################
	
	echo -e "\n==> Checking for Creating GitHub repository"
	sleep 2s
	
	# create repository if it does not exist
	git_missing=$(curl -s https://api.github.com/repos/${GIT_USERNAME}/${pkgname} | grep "Not Found")
	
	if [[ "$git_missing" != "" ]]; then
	
		echo -e "\nRepository missing, creating GitHub repository via API\n"
		sleep 2s
	
		# create repo using git api
		# This is too tricky with globbing/expanding the repo vars, so create a temp command
		
		# create in $HOME for easy identification
		cat<<- EOF> create_git_temp
		#!/bin/bash
		cd BUIDLOC
		curl -u "USERNAME" https://api.github.com/user/repos -d '{"name":"PKGNAME","description":"DESCRIPTION"}'
		EOF
		
		# swap the vars
		DESCRIPTION="$pkgname packged for SteamOS"
		sed -i "s|BUIDLOC|$HOME|g" create_git_temp
		sed -i "s|DESCRIPTION|$DESCRIPTION|g" create_git_temp
		sed -i "s|USERNAME|$GIT_USERNAME|g" create_git_temp
		sed -i "s|PKGNAME|$pkgname|g" create_git_temp
		
		# execute and cleanup
		bash create_git_temp && rm -f create_git_temp
		
	else
	
		# check for dir in $HOME, clone if not there
		if [[ -d "$HOME/${pkgname}" ]]; then
		
			 cd "$HOME/${pkgname}" || exit
			 
		else
		
			echo -e "repository not found at $HOME location, cloning..."
			cd || exit 
			git clone "${git_url}" "${pkgname}"
			cd "${pkgname}" || exit
		
		fi
		
	fi
	
	#################################################
	# Alter Debian packaging files
	#################################################
	
	# Enter new repo
	cd "$HOME/${pkgname}" || exit 
	
	# Add Debianized files to repo
	cp -r ${npm_temp_dir}/${npm_pkg_name}/* .
	
	# add basic readme
	touch README.md
	cat <<-EOF > README.md
	# ${pkgname}
	Converted NPM package
	EOF
	
	echo -e "\n==> Modifying Debian package files"
	sleep 2s
	
	# correct and update resultant files pushed by npm2deb
	
	# changelog
	sed -i "s|UNRELEASED|$dist_rel|g" node-${npm_pkg_name}/debian/changelog
	sed -i "s|FIX_ME debian author|$uploader|g" node-${npm_pkg_name}/debian/changelog
	sed -i "s| (Closes: #nnnn)||g" node-${npm_pkg_name}/debian/changelog
	# control
	sed -i "s|FIX_ME debian author|$uploader|g" node-${npm_pkg_name}/debian/control
	sed -i "s|FIX_ME repo url|$git_url|g" node-${npm_pkg_name}/debian/control
	sed -i "s|FIX_ME debian author|$maintainer|g" node-${npm_pkg_name}/debian/control
	sed -i "s|FIX_ME long description|$description_long|g" node-${npm_pkg_name}/debian/control
	# copyright
	sed -i "s|FIX_ME debian author|$maintainer|g" node-${npm_pkg_name}/debian/copyright
	# watch (optional)
	sed -i "s|FIX_ME repo url|$git_url|g" node-${npm_pkg_name}/debian/watch
	sed -i '/fakeupstream/d' node-${npm_pkg_name}/debian/watch
	
	# Open debian files for confirmation
	file="changelog control copyright watch"
	
	# only edit file if it exists
	for entry in "${file}"
	do
		if [[ -f "$file" ]]; then
		
			nano node-${npm_pkg_name}/debian/${file}
		
		fi
		
	done

	#################################################
	# Sync to remote
	#################################################

	# push changes
	git add .
	git commit -m "update source code from npm2deb"
	git push origin $branch
	
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

}

# start main and log to tmp
main | tee "/tmp/${pkgname}-log-temp.txt"

# convert log file to Unix compatible ASCII
strings "/tmp/${pkgname}-log-temp.txt" > "/tmp/${pkgname}-log.txt"

# strings does catch all characters that I could 
# work with, final cleanup
sed -i 's|\[J||g' "/tmp/${pkgname}-log.txt"

# remove file not needed anymore
rm -f "/tmp/${pkgname}-log-temp.txt"
