#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	kodi-build-all.sh
# Script Ver:	0.5.1
# Description:	Attempts to build all kodi packages and addons into a temporary
#               folder under merge ${HOME}/kodi-all-tmp/
#               This script passes "build_all=yes" to each script.
#
# See:		n/a
# Usage:	kodi-build-all.sh
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


# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "${REMOTE_USER}" == "" || "${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool target(s)
	REMOTE_USER="mikeyd"
	REMOTE_HOST="archboxmtd"

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"
	
else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"
	
fi

# pass build dir var to all scripts
export auto_export build_dir="merge ${HOME}/kodi-all-tmp"
src_dir="${pkgname}-${pkgver}"

# pass auto-build flag
export build_all="yes"

# Set package var overrides here
kodi_release="Isengard"
kodi_tag="15.2-Isengard"

install_prereqs()
{
	echo -e "==> Installing basic build tools\n"
	sleep 2s

	# Install basic build packages
	sudo apt-get install -y --force-yes autoconf automake autopoint autotools-dev bc ccache cmake \
	build-essential

	# create and enter build_dir
	if [[ -d "$auto_build_dir" ]]; then

		sudo rm -rf "$auto_build_dir"
		mkdir -p "$auto_build_dir"

	else

		mkdir -p "$auto_build_dir"

	fi

}

build_all()
{

	clear

	# Install prereqs
	
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	fi


	###########################################################
	# build Kodi prerequisite packages 
	###########################################################
	# Install them for the main builds
	# In the the future, this behavior will be replaced by pbuilder/chroot.

	# STAGE 1
	
	cat <<-EOF
	
	----------------------------------------------------------
	Building stage 1 prerequisite build packages
	----------------------------------------------------------
	EOF
	
	# set pkg list
	pkgs="dcadec platform"


	for pkg in ${pkgs};
	do

		cat <<-EOF

		-------------------------------------
		Building ${pkg}
		-------------------------------------

		EOF
		sleep 3s

		# Find where our script is (takes care of debian/ folders)
		script_dir=$(find -name "build-${pkg}.sh" -printf '%h\n')

		cd "$script_dir"
		if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} built sucessfully"
			sleep 3s

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s
		fi

		# return back to original script dir
		cd $scriptdir

	done

	# Install packages to clean build environment
	echo -e "\v==> Installing Stage 1 prerequisite build packages\n"
	sleep 2s
	echo "y" | sudo gdebi $auto_build_dir/*dcadec*.deb
	echo "y" | sudo gdebi $auto_build_dir/*platform*.deb


	cat <<-EOF
	
	----------------------------------------------------------
	Building stage 2 prerequisite build packages
	----------------------------------------------------------

	EOF

	# STAGE 2
	# set pkg list
	pkgs="kodi-platform libcec afpfs-ng taglib shairplay"

	for pkg in ${pkgs};
	do

		cat <<-EOF

		-------------------------------------
		Building ${pkg}
		-------------------------------------
		EOF
		sleep 3s

                # Find where our script is (takes care of debian/ folders)
                script_dir=$(find -name "build-${pkg}.sh" -printf '%h\n')

                cd "$script_dir"
                if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} built sucessfully"
			sleep 3s

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s
		fi

		# return back to original script dir
                cd $scriptdir

	done

	echo -e "\v==> Installing Stage 2 prerequisite build packages\n"
	echo "y" | sudo gdebi $auto_build_dir/libkodiplatform-dev*.deb
	echo "y" | sudo gdebi $auto_build_dir/libcec*.deb
	echo "y" | sudo gdebi $auto_build_dir/afpfs-ng*.deb
	echo "y" | sudo gdebi $auto_build_dir/taglib*.deb
	echo "y" | sudo gdebi $auto_build_dir/libshair*.deb 
	echo "y" | sudo gdebi $auto_build_dir/shairplay*.deb
	
	# TESTING ONLY
	echo -e "\nExiting stage 1 builds"
	exit 1
	
	cat <<-EOF
	
	----------------------------------------------------------
	Building main Kodi package
	----------------------------------------------------------

	EOF

	###########################################################
	# build Main Kodi package
	###########################################################

	# Kodi proces the packages:
	# kodi-addon-dev, kodi-audio-dev, kodi-bin, kodi-bin, kodi-eventclients-common, kodi-eventclients-dev
	# kodi-eventclients-j2me, kodi-eventclients-ps3, kodi-eventclients-wiiremote, kodi-eventclients-wiiremote
	# kodi-eventclients-xbmc-send, kodi-pvr-dev, kodi-screensaver-dev, kodi-tools-texturepacker, 
	# kodi-tools-texturepacker, kodi-visualization-dev, kodi
	
	# The PVR addons requrie kodi-addon-dev, so build and install kodi first, thent the addons
	pkgs="kodi"

	for pkg in ${pkgs};
	do

		cat <<-EOF

		-------------------------------------
		Building ${pkg}
		-------------------------------------
		EOF
		sleep 3s

		# Find where our script is (takes care of debian/ folders)
                script_dir=$(find -name "build-${pkg}.sh" -printf '%h\n')

                cd "$script_dir"
                if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} built sucessfully"
			sleep 3s
			
			# cleanup temp build dir
			sudo rm -rf build-${pkg}-temp

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s

		fi

		# go back to original scriptdir
		cd "${scriptdir}"

	done
	
	echo -e "\v==> Installing packages required for addon building\n"
	echo "y" | sudo gdebi $auto_build_dir/kodi-addon-dev*.deb

	cat <<-EOF
	
	----------------------------------------------------------
	Building Kodi addons
	----------------------------------------------------------

	EOF

	###########################################################
	# build Kodi addons
	###########################################################

	# Now build Kodi addons	after Kodi is installed
	pkgs="pvr-argustv pvr-demo pvr-dvblink pvr-dvbviewer pvr-filmon pvr-hts \
	pvr-iptvsimple pvr-mediaportal-tvserver pvr-mythtv pvr-nextpvr pvr-njoy pvr-pctv \
	pvr-stalker pvr-vbox pvr-vdr-vnsi pvr-vuplus pvr-wmc kodi-audioencoder-lame \
	kodi-audioencoder-flac"
	
	for pkg in ${pkgs};
	do

		cat <<-EOF

		-------------------------------------
		Building ${pkg}
		-------------------------------------
		EOF
		sleep 3s

		# Find where our script is (takes care of debian/ folders)
                script_dir=$(find -name "build-${pkg}.sh" -printf '%h\n')

                cd "$script_dir"
                if ./build-${pkg}.sh; then

			echo -e "Package ${pkg} built sucessfully"
			sleep 3s
			
			# cleanup temp build dir
			sudo rm -rf build-${pkg}-temp

		else

			echo -e "Package ${pkg} build FAILED. Please review log.txt"
			sleep 3s

		fi

		# go back to original scriptdir
		cd "${scriptdir}"

	done

	###########################################################
	# Summary
	###########################################################

	# inform user of packages
	cat <<-EOF
	
	######################################################################
	If all kodi packages were built without errors you will see them below.
	If you don't, please check the $build_dir/build-log.txt log.
	
	Please remember to update version numbers in the individual build
	scripts if they have changed!
	#########################################################################

	EOF

	echo -e "Showing contents of: $auto_build_dir: \n"
	ls "${auto_build_dir}" | grep -E "${pkgver}" *.deb

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${auto_build_dir}/" ]]; then
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi


}

# start functions
build_all | tee $auto_build_dir/build-log.txt
