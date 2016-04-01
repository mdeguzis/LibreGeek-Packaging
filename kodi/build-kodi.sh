#!/bin/bash
# -------------------------------------------------------------------------------
# Author:    		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	  	build-kodi.sh
# Script Ver:		1.4.1
# Description:		Attempts to build a deb package from kodi-src
#               	https://github.com/xbmc/xbmc/blob/master/docs/README.linux
#               	This is a fork of the build-deb-from-src.sh script. Due to the 
#               	amount of steps to build kodi, it was decided to have it's own 
#               	script. A deb package is built from this script. 
#
# Usage:      		./build-kodi.sh --cores [cpu cores]
#			./build-kodi.sh [--package-deb][--source]
# See Also:		https://github.com/xbmc/xbmc-packaging
# Opts:			[--testing]
#			Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

#################################################
# Set variables
#################################################

# source args
build_opts="$1"
cores_num="$2"

time_start=$(date +%s)
time_stamp_start=(`date +"%T"`)

# remove old log
rm -f "kodi-build-log.txt"

# Specify a final arg for any extra options to build in later
# The command being echo'd will contain the last arg used.
# See: http://www.cyberciti.biz/faq/linux-unix-bsd-apple-osx-bash-get-last-argument/
export final_opts=$(echo "${@: -1}")

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
	REMOTE_PORT="22"

fi



if [[ "$final_opts" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

set_vars()
{

	###################################
	# package vars
	###################################

	pkgname="kodi"
	uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
	maintainer="ProfessorKaos64"
	pkgrev="2"
	DIST="brewmaster"
	urgency="low"
	BUILDER="pdebuild"
	BUILDOPTS="--debbuildopts \"-j4\""
	export STEAMOS_TOOLS_BETA_HOOK="true"
	ARCH="amd64"
	date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
	date_short=$(date +%Y%m%d)
	export build_dir="${HOME}/build-kodi-temp"
	src_dir="${pkgname}-${pkgver}"

	# Set target for git source author
	repo_target="xbmc"

	###################################
	# build vars
	###################################

	# Set path for build dir
	if [[ ! -d "${build_dir}" ]]; then

		mkdir -p "${build_dir}"

	else

		rm -rf "${build_dir}"
		mkdir -p "${build_dir}"

	fi

	# Set git dir based on repo target to avoid recloning for different targets
	if [[ "$repo_target" != "xbmc" ]]; then

		# set git dir to alternate
		export git_dir="${HOME}/kodi-${repo_target}"
	else
		# set build dir to default
		export git_dir="${HOME}/kodi-source"

	fi

	# Set Git URL
	git_url="git://github.com/${repo_target}/xbmc.git"

	###################
	# global vars
	###################

	# Allow more concurrent threads to be specified
	if [[ "$build_opts" == "--cores" ]]; then

		# set cores
		cores="$core_num"

	else

		# default to 2 cores as fallback
		cores="2"
	fi


	# Set script defaults for building packages or source directly
	if [[ "$extra_opts" == "--source" || "$arg1" == "--source" ]]; then

		# set package to yes if deb generation is requested
		package_deb="no"

	elif [[ "$extra_opts" == "--skip-build" || "$arg1" == "--skip-build" ]]; then

		# If Kodi is confirmed by user to be built already, allow build
		# to be skipped and packaging to be attempted directly
		skip_build="yes"
		package_deb="yes"

	else

		# Proceed with default actions
		package_deb="yes"

	fi

	##################################
	# Informational
	##################################

	# Source build notes:
	# https://github.com/xbmc/xbmc/blob/master/docs/README.linux

	# Current version:
	# https://github.com/xbmc/xbmc/blob/master/version.txt

	# model control file after:
	# https://packages.debian.org/sid/kodi

	# Current checkinstall config:
	# cfgs/source-builds/kodi-checkinstall.txt

}

function_install_pkgs()
{

	# cycle through packages defined

	for PKG in ${PKGS};
	do

		# assess via dpkg OR traditional 'which'
		PKG_OK_DPKG=$(dpkg-query -W --showformat='${Status}\n' $PKG | grep "install ok installed")
		#PKG_OK_WHICH=$(which $PKG)

		if [[ "$PKG_OK_DPKG" == "" ]]; then

			echo -e "\n==INFO==\nInstalling package: ${PKG}\n"
			sleep 1s

			if sudo apt-get install ${PKG} -y --force-yes; then

				echo -e "\n${PKG} installed successfully\n"
				sleep 1s

			else
				echo -e "Cannot install ${PKG}. Exiting in 15s. \n"
				sleep 15s
				exit 1
			fi

		elif [[ "$PKG_OK_DPKG" != "" ]]; then

			echo -e "Package ${PKG} [OK]"
			sleep 0.1s

		fi

	done

}

kodi_prereqs()
{

	# Main build dependencies are installed via desktop-software.sh
	# from the software list cfgs/software-lists/kodi-src.txt

	echo -e "\n==> Installing main deps for building\n"
	sleep 2s

	if [[ "${BUILDER}" != "pdebuild" && "${package_deb}" == "yes" ]]; then

		# Javis control file lists 'libglew-dev libjasper-dev libmpeg2-4-dev', but they are not
		# in the linux readme
	
		PKGS="autoconf automake autopoint autotools-dev cmake curl dcadec-dev default-jre \
		gawk gperf libao-dev libasound2-dev libass-dev libavahi-client-dev libavahi-common-dev \
		libbluetooth-dev libbluray-dev libboost-dev libboost-thread-dev libbz2-dev libcap-dev \
		libcdio-dev libcec-dev libcurl4-openssl-dev libcwiid-dev libdbus-1-dev \
		libegl1-mesa-dev libfontconfig1-dev libfribidi-dev libgif-dev libgl1-mesa-dev \
		libiso9660-dev libjpeg-dev libltdl-dev liblzo2-dev libmicrohttpd-dev \
		libmodplug-dev libmpcdec-dev libmysqlclient-dev libnfs-dev libogg-dev libpcre3-dev \
		libplist-dev libpng12-dev libpulse-dev librtmp-dev libsdl2-dev libshairplay-dev \
		libsmbclient-dev libsqlite3-dev libssh-dev libssl-dev libswscale-dev libtag1-dev \
		libtinyxml-dev libtool libudev-dev libusb-dev libva-dev libvdpau-dev libvorbis-dev \
		libxinerama-dev libxml2-dev libxmu-dev libxrandr-dev libxslt1-dev libxt-dev libyajl-dev \
		lsb-release nasm:i386 python-dev python-imaging python-support swig unzip uuid-dev yasm \
		zip zlib1g-dev libcrossguid-dev libglew-dev libjasper-dev libmpeg2-4-dev"
	
		# install dependencies / packages
		function_install_pkgs
	
		#####################################
		# Dependencies - Debian sourced
		#####################################

		echo -e "\n==> Installing build deps for packaging\n"
		sleep 2s

		PKGS="build-essential fakeroot devscripts checkinstall cowbuilder pbuilder debootstrap \
		cvs fpc gdc libflac-dev libsamplerate0-dev libgnutls28-dev"

		# install dependencies / packages
		function_install_pkgs

		echo -e "\n==> Installing specific kodi build deps\n"
		sleep 2s

		# Origin: ppa:team-xbmc/ppa
		# Only install here if not using auto-build script (which installs them after)

		PKGS="libcec3 libcec-dev libafpclient-dev libgif-dev libmp3lame-dev libgif-dev libp8-platform-dev"

		# install dependencies / packages
		function_install_pkgs

		# Origin: ppa:team-xbmc/xbmc-nightly
		# It seems shairplay, libshairplay* are too old in the stable ppa
		PKGS="libshairport-dev libshairplay-dev shairplay"

		# install dependencies / packages
		function_install_pkgs

	elif [[ "${BUILDER}" == "pdebuild" &&  "${package_deb}" == "yes" ]]; then

		# Still need a few basic packages
		sudo apt-get install -y --force-yes curl

	else

		# If we are not packaging a deb, set to master branch build
        	branch="master"
        	pkgver="$kodi_tag"

	fi
}

kodi_package_deb()
{

	# Debian link: 	    https://wiki.debian.org/BuildingTutorial
	# Ubuntu link: 	    https://wiki.ubuntu.com/PbuilderHowto
	# XBMC/Kodi readme: https://github.com/xbmc/xbmc/blob/master/tools/Linux/packaging/README.debian

	# Ensure we are in the proper directory
	cd "$git_dir"

	# only call if not auto-building
	if [[ "$build_all" != "yes" ]]; then

		# show tags instead of branches
		git tag -l --column

		echo -e "\nWhich Kodi release do you wish to build for:"
		echo -e "Type 'master' to use the master tree\n"

		# get user choice
		sleep 0.2s
		read -erp "Release Choice: " kodi_tag

		# set release for upstream xbmc packaging fork
		if echo $kodi_tag | grep -e "Gotham" 1> /dev/null; then kodi_release="Gotham"; fi
		if echo $kodi_tag | grep -e "Isengard" 1> /dev/null; then kodi_release="Isengard"; fi
		if echo $kodi_tag | grep -e "Jarvis" 1> /dev/null; then kodi_release="Jarvis"; fi

		# If the tag is left blank, set to master

		# checkout proper release
		if [[ "$kodi_tag" != "master" ]]; then

			# Check out requested tag
			git checkout "tags/${kodi_tag}"

		else

			# Tags for Krypton are not yet added, add below manually
			#kodi_release="Krypton"
			kodi_tag="auto"

		fi

		# set release for changelog
        	pkgver="${kodi_release}+git+bsos${pkgrev}"

	fi

	# change address in xbmc/tools/Linux/packaging/mk-debian-package.sh 
	# See: http://unix.stackexchange.com/a/16274
	# This was done only at prior a point to satisfy some build deps. This has since
	# been corrected. 'mk-debian-package.sh' handles all package naming and will try
	# to sign as wnsipex. This is ok, since we will sign with reprepro. 

	# However, this is still used to adjust the changelog structure
	# This may be dropped in the future

	# Add any overrides to the build host/arch options below

	if [[ "${kodi_release}" != "" ]]; then

		sed -i "s|\bxbmc/xbmc-packaging/archive/master.tar.gz\b|ProfessorKaos64/xbmc-packaging/archive/${kodi_release}.tar.gz|g" "tools/Linux/packaging/mk-debian-package.sh"

	fi

	############################################################
	# Create setup 
	############################################################

	if [[ "${BUILDER}" == "pbuilder" || "${BUILDER}" == "pdebuild" ]]; then

		# Assess where pbuilder base config is, for multi-box installations
		echo "Where is your pbuilder base folder?" 
		sleep 0.3s
		read -erp "Location: " PBUILDER_BASE

		# Add any overrides for mk-debian-package.sh below
		# The default in the script is '"${BUILDER}"' which will attempt to sign the pkg

		RELEASEV="$kodi_tag" \
		DISTS="$DIST" \
		ARCHS="$ARCH" \
		BUILDER="$BUILDER" \
		PDEBUILD_OPTS="$BUILDOPTS" \
		PBUILDER_BASE="$PBUILDER_BASE" \
		tools/Linux/packaging/mk-debian-package.sh

	else
	
		RELEASEV="$kodi_tag" \
		BUILDER="$BUILDER" \
		PDEBUILD_OPTS="$BUILDOPTS" \
		tools/Linux/packaging/mk-debian-package.sh

	fi

}

kodi_clone()
{

	echo -e "\n==> Cloning the Kodi repository:"
	echo -e "    $git_url"

	# If git folder exists, evaluate it
	# Avoiding a large download again is much desired.
	# If the DIR is already there, the fetch info should be intact

	if [[ -d "$git_dir" ]]; then

		echo -e "\n==Info==\nGit folder already exists! Reclone [r] or pull [p]?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "p" ]]; then
			# attempt to pull the latest source first
			echo -e "\n==> Attempting git pull..."
			sleep 2s

			# attempt git pull, if it doesn't complete reclone
			if ! git pull; then

				# command failure
				echo -e "\n==Info==\nGit directory pull failed. Removing and cloning...\n"
				sleep 2s
				rm -rf "$git_dir"
				# create and clone to merge ${HOME}/kodi
				cd
				git clone ${git_url} ${git_dir}

			fi

		elif [[ "$git_choice" == "r" ]]; then
			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			sudo rm -rf "$git_dir"
			# create and clone to merge ${HOME}/kodi
			cd
			git clone ${git_url} ${git_dir}

		else

			echo -e "\n==> Git directory does not exist. cloning now...\n"
			sleep 2s
			# create and clone to merge ${HOME}/kodi
			cd
			git clone ${git_url} ${git_dir}

		fi

	else

			echo -e "\n==> Git directory does not exist. cloning now...\n"
			sleep 2s
			# create DIRS
			cd
			# create and clone to current dir
			git clone ${git_url} ${git_dir}

	fi

}

kodi_build_src()
{

	#################################################
	# Build Kodi source
	#################################################

	echo -e "\n==> Building Kodi in $git_dir\n"

	# enter build dir
	cd "$git_dir"

	# checkout target release
	git checkout "$branch"

  	# create the Kodi executable manually perform these steps:
	if ./bootstrap; then

		echo -e "\nBootstrap successful\n"

	else

		echo -e "\nBoostrap failed. Exiting in 10 seconds."
		sleep 10s
		exit 1

	fi

	# ./configure <option1> <option2> PREFIX=<system prefix>... 
	# (See --help for available options). For now, use the default PREFIX
        # A full listing of supported options can be viewed by typing './configure --help'.
	# Default install path is:

	# FOR PACKAGING DEB ONLY (TESTING)
	# It may seem that per "http://forum.kodi.tv/showthread.php?tid=80754", we need to
	# export package config. 

	# Configure with bluray support
	# Rmove --disable-airplay --disable-airtunes, not working right now

	if ./configure --prefix=/usr --enable-libbluray --enable-airport; then

		echo -e "\nConfigured successfuly\n"

	else

		echo -e "\nConfigure failed. Exiting in 10 seconds."
		sleep 10s
		exit 1

	fi

	# make the package
	# By adding -j<number> to the make command, you describe how many
     	# concurrent jobs will be used. So for quad-core the command is:

	# make -j4

	# Default core number is 2 if '--cores $n' argument is not specified
	if make -j${cores}; then

		echo -e "\nKodi built successfuly\n"

	else

		echo -e "\nBuild failed. Exiting in 10 seconds."
		sleep 10s
		exit 1

	fi

	# install source build if requested
	echo -e "\n==> Do you wish to install the built source code? [y/n]"

	# get user choice
	sleep 0.2s
	read -erp "Choice: " install_choice

	if [[ "$install_choice" == "y" ]]; then

		sudo make install

	elif [[ "$install_choice" == "n" ]]; then

		echo -e "\nInstallation skipped"

	else

		echo -e "\nInvalid response, skipping installation"

	fi

	# From v14 with commit 4090a5f a new API for binary addons is available. 
	# Not used for now ...

	# make -C tools/depends/target/binary-addons

	####################################
	# (Optional) build Kodi test suite
	####################################

	#make check

	# compile the test suite without running it

	#make testsuite

	# The test suite program can be run manually as well.
	# The name of the test suite program is 'kodi-test' and will build in the Kodi source tree.
	# To bring up the 'help' notes for the program, type the following:

	#./kodi-test --gtest_help

	#################################################
	# Post install configuration
	#################################################

	echo -e "\n==> Adding desktop file and artwork"

	# copy files
	sudo cp "kodi.desktop" "/usr/share/applications"
	sudo cp "Kodi.png" "/home/steam/Pictures"

	# check if Kodi really installed
	if [[ -f "/usr/local/bin/kodi" ]]; then

		echo -e "\n==INFO==\nKodi was installed successfully."

	else

		echo -e "\n==INFO==\nKodi install unsucessfull\n"

	fi

}

show_build_summary()
{

	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)

	cat <<-EOF
	----------------------------------------------------------------
	Summary
	----------------------------------------------------------------
	Time started: ${time_stamp_start}
	Time end: ${time_stamp_end}
	Total Runtime (minutes): $runtime

	EOF
	sleep 2s

	# If "build_all" is requested, skip user interaction
	# Display output based on if we were source building or building
	# a Debian package

	if [[ "$package_deb" == "no" ]]; then

		cat <<-EOF
		If you chose to build from source code, you should now be able 
		to add Kodi as a non-Steam game in Big Picture Mode. Please 
		see see the wiki for more information.

		EOF

	elif [[ "$package_deb" == "yes" ]]; then

		cat <<-EOF
		###############################################################
		If package was built without errors you will see it below.
		If you don't, please check build dependcy errors listed above.
		###############################################################

		EOF

		echo -e "Showing contents of: ${build_dir}: \n"
		ls "${build_dir}"

		echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
		sleep 0.5s
		# capture command
		read -ep "Choice: " transfer_choice

		if [[ "$transfer_choice" == "y" ]]; then

			# transfer files
			if [[ -d "${build_dir}" ]]; then
			rsync -arv -e "ssh -p ${REMOTE_PORT}" --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}


			fi

		elif [[ "$transfer_choice" == "n" ]]; then
			echo -e "Upload not requested\n"
		fi

	fi

}


####################################################
# Script sequence
####################################################
# Main order of operations
main()
{

	# Process main functions
	set_vars
	kodi_prereqs
	kodi_clone

	# Process how we are building
	if [[ "$package_deb" == "yes" ]]; then

		kodi_package_deb

	else
		kodi_build_src

	fi

	# go to summary
	show_build_summary

}

#####################################################
# MAIN
#####################################################
main | tee log_temp.txt

#####################################################
# cleanup
#####################################################

# convert log file to Unix compatible ASCII
strings log_temp.txt > kodi-build-log.txt &> /dev/null

# strings does catch all characters that I could
# work with, final cleanup
sed -i 's|\[J||g' kodi-build-log.txt

# remove file not needed anymore
rm -f "log_temp.txt"
