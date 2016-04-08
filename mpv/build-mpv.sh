#!/bin/bash
# -------------------------------------------------------------------------------
# Author:    	Michael DeGuzis
# Git:	    	https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	build-mpv.sh
# Script Ver:	1.0.0
# Description:	Builds mpv for specific use in building PlexMediaPlayer
#
# See:		https://github.com/mpv-player/mpv
# Usage:        ./build-mpv.sh
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

# upstream URL
git_url="https://github.com/mpv-player/mpv"
branch="v0.16.0"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -nc"
export STEAMOS_TOOLS_BETA_HOOK="true"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgname="mpv"
BUILDER="pdebuild"
pkgrev="1"
pkgsuffix="git+bsos${pkgrev}"
DIST="brewmaster"
urgency="low"
maintainer="ProfessorKaos64"

# set build directories
export build_dir="${HOME}/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	
	# dependencies
	sudo apt-get install -y --force-yes build-essential git pkg-config samba-dev \
	luajit devscripts equivs ladspa-sdk libbluray-dev libbs2b-dev libcdio-paranoia-dev \
	libdvdnav-dev libdvdread-dev libenca-dev libfontconfig-dev libfribidi-dev libgme-dev \
	libgnutls28-dev libgsm1-dev libguess-dev libharfbuzz-dev libjack-jackd2-dev libopenjpeg-dev \
	liblcms2-dev liblircclient-dev liblua5.2-dev libmodplug-dev libmp3lame-dev libopenal-dev \
	libopus-dev libopencore-amrnb-dev libopencore-amrwb-dev librtmp-dev librubberband-dev \
	libschroedinger-dev libsmbclient-dev libssh-dev libsoxr-dev libspeex-dev libtheora-dev \
	libtool libtwolame-dev libuchardet-dev libv4l-dev libva-dev libvdpau-dev libvorbis-dev \
	libvo-aacenc-dev libvo-amrwbenc-dev libvpx-dev libwavpack-dev libx264-dev libxvidcore-dev \
	python-docutils rst2pdf yasm

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

	echo -e "\n==> Obtaining upstream source code\n"

	if [[ -d "${git_dir}" || -f ${build_dir}/*.orig.tar.gz ]]; then

		echo -e "==Info==\nGit source files already exist! Remove and [r]eclone or [k]eep? ?\n"
		sleep 1s
		read -ep "Choice: " git_choice

		if [[ "$git_choice" == "r" ]]; then

			echo -e "\n==> Removing and cloning repository again...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# clean and clone
			sudo rm -rf "${build_dir}" && mkdir -p "${build_dir}"
			git clone -b "${branch}" "${git_url}" "${git_dir}"
			cd "${git_dir}" && git submodule update --init

		else

			# Unpack the original source later on for  clean retry
			# set retry flag
			retry="yes"

		fi

	else

			echo -e "\n==> Git directory does not exist. cloning now...\n"
			sleep 2s
			# reset retry flag
			retry="no"
			# create and clone to current dir
			mkdir -p "${build_dir}" || exit 1
			git clone -b "${branch}" "${git_url}" "${git_dir}"
			cd "${git_dir}" && git submodule update --init

	fi

	#################################################
	# Prepare sources
	#################################################

	# create source tarball
	# For now, do not recreate the tarball if keep was used above (to keep it clean)
	# This way, we can try again with the orig source intact
	# Keep this method until a build is good to go, without error.
	
	if [[ "${retry}" == "no" ]]; then

		echo -e "\n==> Creating original tarball\n"
		sleep 2s
		tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"
		
	else
	
		echo -e "\n==> Cleaning old source folders for retry"
		sleep 2s
		
		rm -rf *.dsc *.xz *.build *.changes ${git_dir}
		mkdir -p "${git_dir}"
	
		echo -e "\n==> Retrying with prior source tarball\n"
		sleep 2s
		tar -xzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" -C "${build_dir}" --totals
		sleep 2s

	fi
	
	# add debian here, after unpack or creation
	cp -r "${scriptdir}/debian" "${git_dir}"

	###############################################################
	# build package
	###############################################################

	# enter source dir
	cd "${git_dir}"

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" \
		-D "${DIST}" -u "${urgency}" "Update release"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" \
		-D "${DIST}" -u "${urgency}" "Initial upload"
		nano "debian/changelog"

	fi
	
	echo -e "\n==> Building Debian package from source\n"
	sleep 2s
	
	#################################################
	# Build mpv
	#################################################
	
	# build debian package
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
