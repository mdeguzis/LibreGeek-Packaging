#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-qt-5.6-alpha.sh
# Script Ver:	0.3.5
# Description:	Builds QT 5.6-alpha for specific use in building PlexMediaPlayer
#
# See:		http://doc.qt.io/qt-5/linux-requirements.html
#		http://wiki.qt.io/Building-Qt-5-from-Git
#
# Usage:	./build-qt-5.6-alpha.sh
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

# files
qt_src_url="http://download.qt.io/development_releases/qt/"
qt_rel="5.6/5.6.0-alpha/single/"
qt_src_file="qt-everywhere-opensource-src-5.6.0-alpha.tar.gz"
qt_src_folder="${qt_src_file%.*.*}"

# package vars
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgname="qt-everywhere-oss"
pkgver="${pkgname}+SteamOS2"
pkgrel="1"
dist_rel="brewmaster"
maintainer="ProfessorKaos64"
provides="qt-everywhere-oss"
pkggroup="utils"
requires=""
replaces=""

# build dirs
build_dir="$HOME/build-${pkgname}-temp"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# dependencies
	sudo apt-get install -y --force-yes libfontconfig1-dev libfreetype6-dev \
	libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev \
	libx11-xcb-dev libxcb-glx0-dev

	# Needed if not passing -qt-xcb
	sudo apt-get install -y --force-yes libxcb-keysyms1-dev libxcb-image0-dev \
	libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
	libxcb-randr0-dev libxcb-render-util0-dev libgl1-mesa-dev

	# Needed for qtwebengine building
	sudo apt-get install -y --force-yes libcap-dev libegl1-mesa-dev x11-xserver-utils \
	libxrandr-dev libxss-dev libxcursor-dev libxtst-dev libpci-dev libdbus-1-dev \
	libatk1.0-dev libnss3-dev re2c gperf flex bison libicu-dev libxslt-dev ruby \
	libssl-doc x11proto-composite-dev libasound2-dev libxcomposite-dev

}

main()
{

	#################################################
	# Fetch source
	#################################################

	# create and enter build_dir
	if [[ -d "$build_dir" ]]; then

		sudo rm -rf "$build_dir"
		mkdir -p "$build_dir"

	else

		mkdir -p "$build_dir"

	fi

	#################################################
	# Build QT 5.6 alpha source
	#################################################

	# install qt-5.6 alpha
	# See: http://doc.qt.io/qt-5/build-sources.html

 	# obtain source
 	echo -e "\n==> Downloading source tarball\n"
	sleep 2s

 	if [[ -f "/tmp/${qt_src_file}" ]]; then

 		echo -e "==> Archive exists, redownload [y/n]?"
 		read -erp "Choice: " dl_choice

 		if [[ "$dl_choice" == "y" ]]; then 

			wget -P /tmp --no-parent --reject "index.html" ${qt_src_url}/${qt_rel}/${qt_src_file}
			mv "/tmp/${qt_src_file}" "${build_dir}"
			tar -xzvf "${build_dir}/$qt_src_file" -C "${build_dir}"
			# rm "/tmp/$qt_src_file"
			cd "${build_dir}/${qt_src_folder}" || exit

		elif [[ "$dl_choice" == "n" ]]; then 

			# Just move and extract only
                        mv "/tmp/${qt_src_file}" "${build_dir}"
                        tar -xzvf "${build_dir}/$qt_src_file" -C "${build_dir}"
                        # rm "/tmp/$qt_src_file"
			cd "${build_dir}/${qt_src_folder}" || exit
		fi

	else

			wget -P /tmp --no-parent --reject "index.html" ${qt_src_url}/${qt_rel}/${qt_src_file}
                        mv "/tmp/${qt_src_file}" "${build_dir}"
                        tar -xzvf "${build_dir}/$qt_src_file" -C "${build_dir}"
                        # rm "/tmp/$qt_src_file"
                        cd "${build_dir}/${qt_src_folder}" || exit

	fi

	# configure opensource version, auto-accept yes
	./configure -confirm-license -prefix $PWD/qtbase -opensource -nomake tests

	# Generate build
	make -j4

	# install build
	# sudo make install

	#################################################
	# Build QT 5.6 alpha source (web engine)
	################################################
	# Ensure liQt5WebEngine.so exists after install

	cd qtwebengine
	qmake
	# Don't use the qmake from the qt4-qmake package, use the qmake of the built Qt, use the full path to it.
	# See: https://forum.qt.io/topic/49031/solved-maps-and-android/4

	../qtbase/bin/qmake
 	make
 	#sudo make install


	#################################################
	# Build Debian package
	#################################################
	
	echo -e "\n==> Building Debian package from source\n"
	sleep 2s

	# use checkinstall
	sudo checkinstall --pkgname="$pkgname" --fstrans="no" --backup="no" \
	--pkgversion="$pkgver" --pkgrelease="$pkgrel" \
	--deldoc="yes" --maintainer="$maintainer" --provides="$provides" --replaces="$replaces" \
	--pkggroup="$pkggroup" --requires="$requires" --exclude="/home"



	#################################################
	# Post install configuration
	#################################################
	
	# TODO
	
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
		cd "$scriptdir"
	else
		cd "$HOME"
	fi
	
	# inform user of packages
	echo -e "\n############################################################"
	echo -e "If package was built without errors you will see it below."
	echo -e "If you don't, please check build dependcy errors listed above."
	echo -e "############################################################\n"
	
	if [[ -d "$git_dir/build" ]]; then
	
		echo -e "Showing contents of: $git_dir/build: \n"
		ls "$git_dir/build" | grep -E *.deb
	
	elif [[ -d "$build_dir" ]]; then
	
		echo -e "Showing contents of: $build_dir: \n"
		ls "${git_dir}/build" | grep -E *.deb

	fi

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -ep "Choice: " transfer_choice
	
	if [[ "$transfer_choice" == "y" ]]; then
	
		# transfer files
		if [[ -d "$git_dir/build" ]]; then
		
			scp ${git_dir}/*${pkgver}* ${USER}@${HOST}:${REPO_FOLDER}
		
		elif [[ -d "$build_dir" ]]; then
		
			scp ${build_dir}/*${pkgver}* ${USER}@${HOST}:${REPO_FOLDER}

		fi
		
	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
install_prereqs
main
