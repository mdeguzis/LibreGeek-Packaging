#!/bin/bash
# -------------------------------------------------------------------------------
# Author:    	  Michael DeGuzis
# Git:	    	  https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	  build-cmake.sh
# Script Ver:	  0.7.9
# Description:	  Attempts to build a deb package from Plex Media Player git source
#                 Installs cmake to '/usr/local/bin/cmake'
# See:		  https://cmake.org/download/
# Usage:	 ./build-cmake.sh
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
git_url="https://cmake.org/cmake.git"

# package vars
date_long=$(date +"%a, %d %b %Y %H:%M:%S %z")
date_short=$(date +%Y%m%d)
ARCH="amd64"
BUILDER="pdebuild"
BUILDOPTS="--debbuildopts -b"
export STEAMOS_TOOLS_BETA_HOOK="false"
pkgname="cmake"
uploader="SteamOS-Tools Signing Key <mdeguzis@gmail.com>"
pkgver="3.5.0"
pkgrev="2"
pkgsuffix="git+bsos"
DIST="brewmaster"
urgency="low"
maintainer="ProfessorKaos64"

# build dirs
export build_dir="$HOME/build-${pkgname}-temp"
src_dir="${pkgname}-${pkgver}"
git_dir="${build_dir}/${src_dir}"

install_prereqs()
{
	clear
	echo -e "==> Installing prerequisites for building...\n"
	sleep 2s
	# install needed packages
	sudo apt-get install -y --force-yes git devscripts build-essential checkinstall \
	debhelper dpkg-dev libarchive-dev libbz2-dev libcurl4-openssl-dev libexpat1-dev \
	libjsoncpp-dev liblzma-dev libncurses5-dev procps python-sphinx qtbase5-dev zlib1g-dev

}

main()
{


	#################################################
	# Fetch source
	#################################################

	# create and enter build_dir
	if [[ -d "${build_dir}" ]]; then

		sudo rm -rf "${build_dir}"
		mkdir -p "${build_dir}"

	else

		mkdir -p "${build_dir}"

	fi

	# Enter build dir
	cd "${build_dir}"

	# install prereqs for build
	if [[ "${BUILDER}" != "pdebuild" ]]; then

		# handle prereqs on host machine
		install_prereqs
		
	else

		# Conflict with Valve's libjs-jquery here, force
		# sudo apt-get install -y --force-yes libjs-jquery="1.11.3+dfsg-4~bpo8+1" \
		# libjs-sphinxdoc sphinx-doc

		# Packages needed before build
		sudo apt-get install -y --force-yes sphinx-common dh-autoreconf \
		libftgl-dev

	fi

	echo -e "\n==> Fetching upstream source\n"

	# Get upstream source
	git clone -b "v${pkgver}" "${git_url}" "${git_dir}"

	#################################################
	# Build cmake source
	#################################################

	echo -e "\n==> Creating original tarball\n"sleep 2s
	sleep 2s

	# create source tarball
	cd "${build_dir}"
	tar -cvzf "${pkgname}_${pkgver}+${pkgsuffix}.orig.tar.gz" "${src_dir}"

	# copy in debian folder
	cp -r "$scriptdir/debian" "${git_dir}"

	# enter source dir
	cd "${git_dir}"

	# gather commits
	commits_full=$(git log --pretty=format:"  * %cd %h %s")

	echo -e "\n==> Updating changelog"
	sleep 2s

 	# update changelog with dch
	if [[ -f "debian/changelog" ]]; then

		dch -p --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package "${pkgname}" \
		-D "${DIST}" -u "${urgency}" "Enable OpenSSL support"
		nano "debian/changelog"

	else

		dch -p --create --force-distribution -v "${pkgver}+${pkgsuffix}-${pkgrev}" --package "${pkgname}" \
		-D "${DIST}" -u "${urgency}" "Initial upload"

	fi

	#################################################
	# Build Debian package
	#################################################

	echo -e "\n==> Building Debian package ${pkgname} from source\n"
	sleep 2s

	#  build
	DIST=$DIST ARCH=$ARCH ${BUILDER} ${BUILDOPTS}

	#################################################
	# Cleanup
	#################################################

	# note time ended
	time_end=$(date +%s)
	time_stamp_end=(`date +"%T"`)
	runtime=$(echo "scale=2; ($time_end-$time_start) / 60 " | bc)

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
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
