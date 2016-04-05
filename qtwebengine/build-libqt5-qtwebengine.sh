#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-qtwebengine.sh
# Script Ver:	1.0.0
# Description:	Builds package of QT 5.6.0 "qtwebengine"
#
# See:		http://code.qt.io/cgit/qt/qtwebengine.git/
#		https://wiki.qt.io/How_to_Try_QtWebEngine#Building_QtWebengine
#
# Usage:	build-qtwebengine.sh
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
	REMOTE_PORT="22"

fi



if [[ "$arg1" == "--testing" ]]; then

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming_testing"

else

	REPO_FOLDER="/home/mikeyd/packaging/SteamOS-Tools/incoming"

fi

# upstream vars
#git_url="git://code.qt.io/qt/qtwebengine.git"
#git_url="https://github.com/qtproject/qtwebengine"
git_url="https://code.qt.io/qt/qt5.git"
branch="dev"
target_branch="5.6"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -sa"
export STEAMOS_TOOLS_BETA_HOOK="true"
export USE_NETWORK="yes"
pkgname="libqt5-qtwebengine"
pkgver="5.6.0"
pkgrev="1"
pkgsuffix="git+bsos"
DIST="brewmaster"
urgency="low"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
maintainer="ProfessorKaos64"

# set build_dir
export build_dir="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s

	# install basic build packages
	sudo apt-get install bison build-essential gperf flex ruby python libasound2-dev libbz2-dev libcap-dev \
	libcups2-dev libdrm-dev libegl1-mesa-dev libgcrypt11-dev libnss3-dev libpci-dev libpulse-dev libudev-dev \
	libxtst-dev gyp ninja qtbase5-dev
	
	# qt packages from brewmaster_testing
	sudo apt-get install -y --force-yes libqt5concurrent5 libqt5dbus5 libqt5libqgtk2 libqt5opengl5-dev \
	libqt5opengl5 libqt5printsupport5 libqt5sql5-ibase libqt5sql5 libqt5sql5-mysql libqt5sql5-odbc \
	libqt5sql5-psql libqt5sql5-sqlite libqt5sql5-tds libqt5test5 libqt5widgets5 libqt5xml5 qt5-default \
	qt5-qmake qtbase5-dev-tools qtbase5-private-dev

}

main()
{

	# install prereqs for build

	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs

	else

		# required for dh_clean
		sudo apt-get install -y --force-yes pkg-kde-tools

	fi

	# Clone upstream source code and branch

	echo -e "\n==> Obtaining upstream source code\n"

	if [[ -d "${git_dir}" ]]; then

		echo -e "==Info==\nGit folder already exists! Remove and [r]eclone or [k]eep? ?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			sudo rm -rf "${build_dir}" && mkdir -p "${build_dir}"
			git clone "${git_url}" "${git_dir}"
			cd "${git_dir}"
			./init-repository --module-subset=qtwebchannel,qtwebengine
			git checkout "${target_branch}"

		else

			# Discard any created files, update modules
			cd "${git_dir}" && git stash && git pull
			./init-repository --module-subset=qtwebchannel,qtwebengine
			git checkout "${target_branch}"

		fi

	else

			echo -e "\n==> Git directory does not exist. cloning now...\n"
			sleep 2s
			# create and clone to current dir
			mkdir -p "${build_dir}" || exit 1
			git clone "${git_url}" "${git_dir}"
			cd "${git_dir}"
			./init-repository --module-subset=qtwebchannel,qtwebengine
			git checkout "${target_branch}"

	fi

	# trim git
	# rm -rf "${git_dir}/.git"

	# add debian/
	cp -r "${scriptdir}/debian" "${git_dir}"

	#################################################
	# Prep source
	#################################################

	echo -e "\n==> Creating original tarball\n"
	sleep 2s

	# create source tarball
	cd "${build_dir}"
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	###############################################################
	# build package
	###############################################################

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Update release"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package \
		"${pkgname}" -D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"
	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

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

	# inform user of packages
	cat<<-EOF

	###############################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependcy errors listed above.
	###############################################################

	Showing contents of: ${build_dir}

	EOF

	ls "${build_dir}" | grep -E "${pkgver}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" \
			${build_dir}/ ${REMOTE_USER}@${REMOTE_HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
