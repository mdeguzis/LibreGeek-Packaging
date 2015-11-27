#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	kodi-build-all.sh
# Script Ver:	0.5.1
# Description:	Attempts to build all kodi packages and addons into a temporary
#               folder under $HOME/kodi-all-tmp/
#               This script passes "build_all=yes" to each script.
#
# See:		n/a
# Usage:	kodi-build-all.sh
# -------------------------------------------------------------------------------

##############################
# Vars
##############################

scriptdir=$(pwd)

# pass build dir var to all scripts
export auto_build_dir="$HOME/kodi-all-tmp"

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
	install_prereqs

	###########################################################
	# build Kodi prerequisite packages 
	###########################################################
	# Install them for the main builds
	# In the the future, this behavior will be replaced by pbuilder/chroot.

	# STAGE 1
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
	echo -e "--> Installing Stage 1 prerequisite build packages\n"
	sleep 2s
	echo "y" | sudo gdebi $auto_build_dir/*dcadec*.deb
	echo "y" | sudo gdebi $auto_build_dir/*platform-dev*.deb

	# STAGE 2
	# set pkg list
	pkgs="kodi-platform libcec afpfs-ng taglib"

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

	echo "y" | sudo gdebi $auto_build_dir/libkodiplatform-dev*.deb
	echo "y" | sudo gdebi $auto_build_dir/libcec*.deb
	echo "y" | sudo gdebi $auto_build_dir/afpfs-ng*.deb
	echo "y" | sudo gdebi $auto_build_dir/taglib*.deb

	# TESTING ONLY
	echo -e "\nExiting stage 1 builds"
	exit 1

	###########################################################
	# build Main Kodi package and pvr addons
	###########################################################

	pkgs="kodi pvr-argustv pvr-demo pvr-dvblink pvr-dvbviewer pvr-filmon pvr-hts \
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
		cd "$scriptdir"

	done

	###########################################################
	# Summary
	###########################################################

	# inform user of packages
	echo -e "\n#######################################################################"
	echo -e "If all kodi packages were built without errors you will see them below."
	echo -e "If you don't, please check the $build_dir/build-log.txt log."
	echo -e "#########################################################################\n"

	echo -e "Showing contents of: $auto_build_dir: \n"
	ls "${auto_build_dir}" | grep -E *.deb

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# cut files
		if [[ -d "${auto_build_dir}/" ]]; then
			scp ${auto_build_dir}/*.deb mikeyd@archboxmtd:/home/mikeyd/packaging/SteamOS-Tools/incoming

		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi


}

# start functions
build_all | tee $auto_build_dir/build-log.txt
