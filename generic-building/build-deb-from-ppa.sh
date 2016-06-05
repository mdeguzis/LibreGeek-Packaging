#!/bin/bash

# -------------------------------------------------------------------------------
# Author:    	Michael DeGuzis
# Git:	    	https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-deb-from-PPA.sh
# Script Ver:	1.1.6
# Description:	Attempts to build a deb package from a PPA. Designed only for
#		Debian systems.
#
# See also:	Generate a source list: http://repogen.simplylinux.ch/
#		Command 'rmadison' from devscripts to see arch's
#		Command 'apt-cache madison <PKG>'
#
# Usage:	./build-deb-from-PPA.sh
#		source ./build-deb-from-PPA.sh
#		./build-deb-from-PPA.sh --ignore-deps
#		./build-deb-from-PPA.sh --binary
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

# build vars
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b --debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgsuffix="bsos"
urgency="low"
pkgrev="1"

# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool pkgname(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"
	REMOTE_PORT="22"

fi


if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

###############################
# Notes regarding some sources
###############################

# Ubuntu packages are not "PPA's" so example deb-src lines are:
# deb-src http://archive.ubuntu.com/ubuntu wily main restricted universe multiverse
# GPG-key(s): 437D05B5, C0B21F32

show_help()
{
	clear
	cat <<-EOF
	####################################################
	Usage:
	####################################################
	./build-deb-from-PPA.sh
	./build-deb-from-PPA.sh --help
	./build-deb-from-PPA.sh --ignore-deps
	source ./build-deb-from-PPA.sh

	The fourth option, preeceded by 'source' will 
	execute the script in the context of the calling 
	shell and preserve vars for the next run.
9
	IF you see the message:
	WARNING: The following packages cannot be authenticated!...
	Look above in the output for apt-get update. You will see a
	line for 'NO_PUBKEY 3B4FE6ACC0B21F32'. Import this key string
	by issuing 'gpg_import.sh <key>' from the extra DIR of this repo.

	EOF

}

if [[ "$arg1" == "--help" ]]; then

	#show help
	show_help
	exit 1

fi

install_prereqs()
{

	clear
	# set scriptdir
	scriptdir="$pwd"

	echo -e "==> Checking for Debian sources..."

	# check for repos
	sources_check=$(sudo find /etc/apt -type f -name "jessie*.list")
	sources_check2=$(grep -r jessie /etc/apt/sources.list)

	if [[ "$sources_check" == "" && "$sources_check2" == "" ]]; then
                echo -e "\n==INFO==\nSources do *NOT* appear to be added at first glance. Adding now..."
                sleep 2s
                "$scriptdir/add-debian-repos.sh"
        else
                echo -e "\n==INFO==\nJessie sources appear to be added."
                sleep 2s
        fi

        echo -e "\n==> Installing build tools...\n"
        sleep 2s

        sudo apt-get install -y --force-yes devscripts build-essential checkinstall \
        ubuntu-archive-keyring devscripts

}

main()
{

	export build_dir="${HOME}/build-deb-temp"
	src_dir="${pkgname}-${pkgver}"

	# remove previous dirs if they exist
	if [[ -d "${build_dir}" ]]; then
	
		sudo rm -rf "${build_dir}"
		
		# cleanup gpg list
		rm -f /tmp/gpg-strings.txt

	fi

	# create build dir and enter it
	mkdir -p "${build_dir}"
	cd "${build_dir}"

	# Ask user for repos / vars
	echo -e "\n==> Please enter or paste the deb-src URL now:"
	echo -e "    [Press ENTER to use last: $repo_src]\n"

	# set tmp var for last run, if exists
	repo_src_tmp="$repo_src"
	
	if [[ "$repo_src" == "" ]]; then
		# var blank this run, get input
		read -ep "deb-src URL: " repo_src
	else
		read -ep "deb-src URL: " repo_src
		# user chose to keep var value from last
		if [[ "$repo_src" == "" ]]; then
			repo_src="$repo_src_tmp"
		else
			# keep user choice
			repo_src="$repo_src"
		fi
	fi

	echo -e "\n==> Use a public key (s)tring or URL to public key (f)ile [s/f]?"
	sleep .2s
	read -erp "Type: " gpg_type
	echo ""

	if [[ "$gpg_type" == "f" ]]; then

                # var blank this run, get input
		read -erp "Enter path to gpg file: " gpg_pub_key

	else

		# Asume GPG string type s
		gpg_type="s"

		# var blank this run, get input
		gpg_pub_key="temp"
		rm -f /tmp/gpg-strings.txt

		while [[ "${gpg_pub_key}" != "" ]];
		do
			read -erp "Enter GPG public key string: " gpg_pub_key
			if [[ "${gpg_pub_key}" != "" ]]; then
				echo "${gpg_pub_key}" >> /tmp/gpg-strings.txt
			fi

		done

	fi

	echo -e "\n==> Please enter or paste the desired package name now:"
	echo -e "    [Press ENTER to use last: $pkgname]\n"
	pkgname_tmp="$pkgname"
	if [[ "$pkgname" == "" ]]; then
		# var blank this run, get input
		read -ep "Package Name: " pkgname
	else
		read -ep "Package Name: " pkgname
		# user chose to keep var value from last
		if [[ "$pkgname" == "" ]]; then
			pkgname="$pkgname_tmp"
		else
			# keep user choice
			pkgname="$pkgname"
		fi
	fi

	# prechecks
	echo -e "\n==> Attempting to add source list"
	sleep 2s

	# check for existance of pkgname, backup if it exists
	if [[ -f /etc/apt/sources.list.d/${pkgname}.list ]]; then
		echo -e "\n==> Backing up ${pkgname}.list to ${pkgname}.list.bak"
		sudo mv "/etc/apt/sources.list.d/${pkgname}.list" "/etc/apt/sources.list.d/${pkgname}.list.bak"
	fi

	# add source to sources.list.d/
	echo ${repo_src} > "${pkgname}.list.tmp"
	sudo mv "${pkgname}.list.tmp" "/etc/apt/sources.list.d/${pkgname}.list"

	echo -e "\n==> Adding GPG keys:\n"
	sleep 2s

	if [[ "$gpg_type" == "s" && -f /tmp/gpg-strings.txt ]]; then

		# loop until there are no more keys in the file
		while read -r gpg_string
		do
			sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $gpg_string

		done < /tmp/gpg-strings.txt

	elif [[ "$gpg_type" == "f" ]]; then

		# add key by specifying URL to public.key equivalent file
		wget -q -O- ${gpg_pub_key} | sudo apt-key add -

	else

		# add gpg key by string from keyserver (fallback default)
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${gpg_pub_key}

	fi

	echo -e "\n==> Updating system package listings...\n"
	sleep 2s
	sudo apt-key update
	sudo apt-get update

	# assign value to build folder for exit warning below
	build_folder=$(ls -l | grep "^d" | cut -d ' ' -f12)

	# assess if depdencies should be installed locally.

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		echo -e "\n==> Attempting to auto-install build dependencies\n"

		# attempt to get build deps
		if sudo apt-get build-dep ${pkgname} -y --force-yes; then

			echo -e "\n==INFO==\nSource package dependencies successfully installed."

		else

			echo -e "\n==ERROR==\nSource package dependencies coud not be installed!"
			echo -e "Press CTRL+C to exit now. Exiting in 15 seconds."
			sleep 15s
			exit 1

		fi
		
	fi
	
	
	# assess arguments

	if [[ "$arg1" == "" ]]; then
	
		#################################################
		# Prepare
		#################################################

		# Get source
		apt-get source "${pkgname}"
		
		# rename source files so they reflect our steamos pkgname
		# Account for bp08 / ubuntu
		find . -maxdepth 1 -exec rename "s|~bpo8|+$pkgsuffix|" {} \;
		find . -maxdepth 1 -exec rename "s|~ubuntu|+$pkgsuffix|" {} \;
		
		# Get versioning
		pkgver=$(find "${build_dir}" -maxdepth 1 -type d -iname "${pkgname}*" \
		-exec basename {} \; | sed "s|${pkgname}-||") && echo $pkgver

		# Enter source dir
		cd ${pkgname}* || exit 1

		echo -e "\nUpdating Changlog"
		
		if [[ -f "debian/changelog" ]]; then

			dch -p --force-bad-version -v \
			"${pkgver}+${pkgsuffix}-${pkgrev}" --package \
			"${pkgname}" -D "${DIST}" -u "${urgency}" "Rebuild for SteamOS"
			nano "debian/changelog"

		else

			dch -p --create --force-bad-version --allow-lower-version \
			-v "${pkgver}+${pkgsuffix}-${pkgrev}" --package \
			"${pkgname}" -D "${DIST}" -u "${urgency}" "Rebuild for SteamOS"

		fi
		
		#################################################
		# Build package
		#################################################
	
		echo -e "\n==> Building Debian package ${pkgname} from PPA source\n"
		sleep 2s
	
		#  build
		sudo -E DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}


	elif [[ "$arg1" == "--ignore_deps" ]]; then

		# There are times when specific packages are specific in the depends lines
		# of Ubuntu control files are satisfied by other packages.

		# One example is libstdc++6.4.4-dev, which seems to be satisfiable by 
		# libstdc6 in Jessie, where only higher ver. dbg packages are available
		# Ex. https://packages.debian.org/search?suite=jessie&searchon=names&keywords=libstdc%2B%2B6

		echo -e "\n==INFO==\nIgnoring depedencies for build\n"
		sleep 2s

		# download source
		apt-get source ${pkgname}

		# identify folder
		cd $build_dir
		build_source_dir=$(ls -d */)

		# build using typicaly commands + override option
		cd ${build_source_dir} && sudo -E DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}


	elif [[ "$arg1" == "--binary-only" ]]; then


                echo -e "\n==INFO==\nBuilding binary only\n"
                sleep 2s

                # download source
                apt-get source ${pkgname}

                # identify folder
                cd $build_dir
                build_source_dir=$(ls -d */)

                # build using typicaly commands + override option
                cd ${build_source_dir} && sudo -E DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	fi

	# back out of build temp to script dir if called from git clone
	if [[ "${scriptdir}" != "" ]]; then
		cd "$scriptdir/generic-building"
	else
		cd "${HOME}"
	fi

	# inform user of packages
	cat<<- EOF
	###################################################################
	If package was built without errors you will see it below.
	If you do not, please check build dependcy errors listed above.
	You could also try manually building outside of this script with
	the following commands (at your own risk!)
	
	cd $build_dir
	cd $build_folder
	sudo dpkg-buildpackage -b -d -uc
	###################################################################

	EOF
	
	ls "${HOME}/build-deb-temp"


	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
			rsync -arv --info=progress2 -e "ssh -p ${REMOTE_PORT}" \
			--filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}


	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

	echo -e "\n==> Would you like to purge this source list addition? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " purge_choice

	if [[ "$purge_choice" == "y" ]]; then

		# remove list
		sudo rm -f /etc/apt/sources.list.d/${pkgname}.list
		sudo apt-get update

	elif [[ "$purge_choice" == "n" ]]; then

		echo -e "Purge not requested\n"
	fi


}

# start main
main
