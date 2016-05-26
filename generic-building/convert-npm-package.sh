#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	convert-npm-package.sh
# Script Ver:	1.3.8
# Description:	Builds simple Debian package from npm module and uploads to 
#		GitHub. Creates repo if it doesn't exist.
#
# See:		https://www.npmjs.com/package/npm-package-search
# See:		https://wiki.debian.org/Javascript/Nodejs/Npm2Deb
#
# Usage:	./convert-npm-package.sh [npm_module]
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

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
npm_pkgname="$1"
pkgname="${npm_pkgname}"
upstream_rev="1"
pkgrev="1"
dist_rel="brewmaster"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"
DESCRIPTION="Debianized $npg_pkg_name, packaged for SteamOS"
description_long="Converted Debain package using npm2deb"

# upstream vars
branch="master"
GIT_USERNAME="ProfessorKaos64"
git_url="https://github.com/${GIT_USERNAME}/${pkgname}.git"

# set build_dirs
npm_tmp_dir="$HOME/${pkgname}-temp"
local_git_dir="$HOME/${pkgname}-git"
npm_top_dir="${npm_tmp_dir}/${npm_pkgname}/node-${npm_pkgname}"
debian_dir="${npm_top_dir}/debian"

# bail out if not arg
if [[ "$npm_pkgname" == "" ]]; then
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

create_new_repo()
{
	
	#################################################
	# Create bare repo
	#################################################
	
	# create new repo in $HOME for easy identification
	cat<<- EOF> create_git_temp
	#!/bin/bash
	echo "Creating repositry PKGNAME"
	curl -u "USERNAME" https://api.github.com/user/repos -d '{"name":"PKGNAME","description":"DESCRIPTION"}'
	EOF
	
	# swap the vars
	sed -i "s|DESCRIPTION|$DESCRIPTION|g" create_git_temp
	sed -i "s|USERNAME|$GIT_USERNAME|g" create_git_temp
	sed -i "s|PKGNAME|$pkgname|g" create_git_temp
	
	# execute
	bash create_git_temp
	
	# clone the empty repository to write to
	echo -e "\n==> Cloning our new base repository\n"
	sleep 2s
	
	if [[ -d "${local_git_dir}" ]]; then
	
		cd "${local_git_dir}" && echo -e ""
		git pull
	
	else
	
		git clone "${git_url}" "${local_git_dir}"
		cd "${local_git_dir}" || exit
		
	fi
	
	cat<<- EOF
	
	#############################################################
	What type of upstream files are we dealing with?
	#############################################################

	(1) GitHub
	(2) Source from NPM JSON file (please verify in debian/watch)
	(e) exit script

	EOF
	
	# the prompt sometimes likes to jump above sleep
	sleep 0.5s
	
	read -ep "Choice: " source_choice
	
	case "$source_choice" in
	        
	        1)
	        
	        # using GitHub
	        read -erp "Enter GitHub repository: " upstream_source
	        git clone "${upstream_source}" "/tmp/source_tmp" 
	        cd "/tmp/source_tmp"
	        
	        # Checkout tag# show tags instead of branches
		git tag -l --column

		echo -e "\nWhich  release do you wish to build for:"
		echo -e "Type 'master' to use the master tree\n"

		# get user choice
		sleep 0.2s
		read -erp "Release Choice: " tag_choice

		# checkout proper release
		git checkout "tags/${tag_choice}"
	        
	        # copy source files and cleanup
	        cd "${local_git_dir}" || exit
	        cp -rv /tmp/source_tmp/* . && rm -rf /tmp/source_tmp
	        ;;
	        
	        2)
	        # Source the upstream URL
		upstream_source=$(npm2deb view ${npm_pkgname} | cut -c 41-100)
		;;
	         
	        *|e)
	        echo -e "\n==ERROR==\nFile type not supported or exit requeste\n"
	        exit 1
		;;
		
	esac
	
	
}

update_debian_files()
{

	#################################################
	# Alter Debian packaging files
	#################################################
	
	echo -e "\n==> Modifying Debian package files"
	sleep 2s

	# add basic readme
	touch README.md
	cat <<-EOF > README.md
	# ${pkgname}
	Converted NPM package
	EOF

	# changelog
	sed -i "s|UNRELEASED|${dist_rel}|g" "${local_git_dir}/debian/changelog"
	sed -i "s|FIX_ME debian author|${uploader}|g" "${local_git_dir}/debian/changelog"
	sed -i "s| (Closes: #nnnn)||g" "${local_git_dir}/debian/changelog"
	# control
	sed -i "s|FIX_ME debian author|${uploader}|g" "${local_git_dir}/debian/control"
	sed -i "s|FIX_ME repo url|${upstream_source}|g" "${local_git_dir}/debian/control"
	sed -i "s|FIX_ME debian author|${maintainer}|g" "${local_git_dir}/debian/control"
	sed -i "s|FIX_ME long description|${description_long}|g" "${local_git_dir}/debian/control"
	# copyright
	sed -i "s|FIX_ME debian author|${maintainer}|g" "${local_git_dir}/debian/copyright"
	# watch (optional)
	sed -i "s|# Origin url: FIX_ME repo url|Origin url: ${upstream_source}|g" "${local_git_dir}/debian/watch"
	sed -i '/fakeupstream/d' "${local_git_dir}/debian/watch"

	# Open debian files for confirmation
	files="changelog control copyright watch"

	# only edit file if it exists
	for file in ${files};
	do
		if [[ -f "${local_git_dir}/debian/$file" ]]; then

			nano "${local_git_dir}/debian/$file"

		fi

	done

	# update if watch file exists with github url 
	if grep "${upstream_source}" "${local_git_dir}/debian/watch"; then

		# pull upstream source based on watch file
		echo -e "Updating against upstream from info in debian/watch\n"
		uscan --download-current-version

	fi

}

git_sync_to_remote()
{

	# push changes
	git add .
	git commit -m "update source code from npm2deb"
	git push origin $branch

}

main()
{

	# clean build files
	rm -rf "/tmp/source_tmp"
	rm -rf "$npm_tmp_dir"
	
	# create temp dir for npm files
	mkdir -p "$npm_tmp_dir"

	# enter build dir
	cd "${npm_tmp_dir}" || exit

	# install prereqs for build
	install_prereqs
	
	#################################################
	# Search and validate
	#################################################
	
	echo -e "\n==> Check for existance of: ${npm_pkgname}?"
	echo -e "    (building local index takes time!)\n"
	sleep 0.5s
	
	read -erp "Choice [y/n]: " search_npm
	
	if [[ "$npm_exists" == "y" ]]; then
	
		# search
		npm search ${npm_pkgname}

	fi

	echo -e "\n==> Please review the dependencies for package: ${npm_pkgname}"
	sleep 2s
	
	echo -e "\nGenerating dependency list, please wait..."
	npm2deb depends -b -r ${npm_pkgname} &> ${npm_pkgname}.deps
	less ${npm_pkgname}.deps
	
	read -erp "Continue? [y/n]: " continue_choice
	sleep 0.5s
	
	if [[ "$continue_choice" != "y" ]]; then
		exit 1
	fi

	echo -e "\n==> Checking if someone else has already started working on this module..."
	sleep 2s
	
	npm2deb search "${npm_pkgname}"
	
	#################################################
	# Create package files
	#################################################
	
	echo -e "==> Per the above, Has anyone started packaging this module?\n"
	sleep 1s
	
	read -erp "Choice [y/n]: " npm_exists
	
	if [[ "${npm_exists}" == "n" ]]; then
		
	
		# create
		echo -e "Creating base files..."
		npm2deb create ${npm_pkgname}
		
	else
	
		# view module
		echo -e "\nPlease review the upstream packages\n"
		exit 1
	
	fi
	
	#################################################
	# Process options
	#################################################
	
	echo -e "\n==> Checking for existance of our GitHub repository..."
	sleep 2s
	
	# create repository if it does not exist
	# test against pkgname or npm-pkgname
	git_missing=$(curl -s https://api.github.com/repos/${GIT_USERNAME}/${pkgname} | grep "Not Found")

	if [[ "$git_missing" != "" ]]; then
		
		cat<<- EOF

		==> It doesn't seem we have a github repository. Fork an 
		    upstream repository, create a new one, or just make debian files?\n"
		
		EOF

		sleep 0.5s
		read -erp "Choice: [fork|new|just-debian]: " git_choice
		
		# create repo using git api
		# This is too tricky with globbing/expanding the repo vars, so create a temp command
		
		if [[ "$git_choice" == "fork" ]]; then
		
			# fork on GitHub.com using hub binrary
			file="v2.2.3/hub-linux-amd64-2.2.3.tgz"
			wget -O hub.tgz \
			"https://github.com/github/hub/releases/download/${file}" -q --show-progress
			
			# fork repo using hub (warning will output if fork exists)
			# See: https://hub.github.com/
			read -erp "Repo to fork?: " git_url
			git clone "${git_url}" "${local_git_dir}"
			hub-linux-amd64*/bin/hub fork
			
			# Add Debianized files to repo
			echo -e "\n==> Injecting Debian files\n"

			sleep 2s
			cd "${local_git_dir}"
			cp -ri ${debian_dir} .
			
			# update debian files
			update_debian_files
			
			# Update git repo
			git_sync_to_remote

		elif [[ "$git_choice" == "just-debian" ]]; then

			# Setup fake target
			local_git_dir="${npm_top_dir}"
			update_debian_files

			# Ask to copy elsewhere, if desired
			cat<<- EOF

			==> Copy debian files to alternate location? 
			    Please use an absolute path. [y/n]"
			
			EOF

			sleep 0.3s && read -erp "Choice: " copy_debian

			if [[ "${copy_debian}" == "y" ]]; then

				read -erp "Location: " debian_target_path
				cp -r "${debian_dir}" "${debian_target_path}"
	
			fi

		else

			# use function to create
			create_new_repo

			# Add Debianized files to repo
			echo -e "\n==> Injecting Debian files\n"

			sleep 2s
			cd "${local_git_dir}"
			cp -ri ${debian_dir} .

			# Update debian files
			update_debian_files

			# Update git repo
			git_sync_to_remote

		fi
	
	# git repo upstream exists	
	else

		# clone
		if [[ ! -d "${local_git_dir}" ]]; then

			git clone "${git_url}" "${local_git_dir}"
			
		else 

			cd "${local_git_dir}"
			git pull

		fi
		
		# update debian files
		update_debian_files
		
		# Update git repo
		git_sync_to_remote

	# end debian/github logic
	fi

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
