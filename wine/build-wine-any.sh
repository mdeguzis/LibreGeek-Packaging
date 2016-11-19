#!/bin/bash

# Description: Builds and installs a 32bit and 64bit version of wine 
# from git://source.winehq.org/git/wine.git to a seperate directory
# Scripts accepts a few arguments, use -h to list 
# See: https://wiki.winehq.org/Building_Wine

# Some build options mirrored from: 
# https://git.archlinux.org/svntogit/community.git/tree/trunk/PKGBUILD?h=packages/wine

build_wine()
{

	WINE_BUILD_ROOT="${HOME}/wine-builds"
	WINE_GIT_ROOT="${WINE_BUILD_ROOT}/wine-git"

	WINE_TARGET_DIR_32="${WINE_BUILD_ROOT}/wine-$WINE_VERSION"
	WINE_TARGET_LIB_DIR_32="${WINE_TARGET_DIR}/lib"
	WINE_TARGET_DIR_64="${WINE_BUILD_ROOT}/wine-$WINE_VERSION"
	WINE_TARGET_LIB_DIR_64="${WINE_TARGET_DIR}/lib"	

	mkdir -p "${WINE_BUILD_ROOT}"
	mkdir -p "${WINE_GIT_ROOT}"
	mkdir -p "${WINE_TARGET_DIR_32}"
	mkdir -p "${WINE_TARGET_LIB_DIR_32}"
	mkdir -p "${WINE_TARGET_DIR_64}"
	mkdir -p "${WINE_TARGET_LIB_DIR_64}"

	# Set default ARCH
	if [[ "${ARCH}" == "" ]]; then

		ARCH="amd64"

	fi

	CURRENT_DIR=$(dirname $(readlink -f "$0"))

	if [ ! -d "${WINE_BUILD_ROOT}" ]; then
		echo "Cloning Wine source code"
		git clone git://source.winehq.org/git/wine.git "${WINE_GIT_ROOT}"
	fi

	# Prep git source
	cd "${WINE_GIT_ROOT}"
	echo "Updating Wine source code"
	git checkout master
	git reset --hard
	git clean -dxf
	git fetch origin
	git checkout wine-$WINE_VERSION

	cat<<-EOF 

	# Get rid of old build dirs
	rm -rf "${WINE_BUILD_ROOT}/wine-{32,64}-build"
	mkdir -p "${WINE_BUILD_ROOT}/wine-{32,64}-build"

	# Check if an existing wine build result exists
	
	if [[ -d "${WINE_TARGET_DIR}" ]]; then

		cat<<- EOF
		
		NOTICE: You may have already built this versio nof wine.
		Please check/remove ${WINE_BUILD_ROOT}/wine-$WINE_VERSION"
		before continuing...

		EOF
		sleep 3s
		exit 1

	else
	
		# Make sure our destination exists
		mkdir -p "${WINE_BUILD_ROOT}/wine-$WINE_VERSION"

	fi


	# All good to go!?

	cat<<- EOF

	----------------------------------------------
	Building Wine ${WINE_VERSION} for 32 bit
	----------------------------------------------

	EOF

	cd "${WINE_BUILD_ROOT}/wine-32-build"

	sleep 2s

	./configure --prefix=$TARGET_DIR \
		--prefix=${WINE_TARGET_DIR_32}/ \
		--libdir=${WINE_TARGET_LIB_DIR_32} \
		--with-x \
		--with-gstreamer \
		--enable-win64

	make depend
	make

	echo "Installing Wine 32 bit"
	make install

	cat<<-EOF 
	
	----------------------------------------------
	Building Wine ${WINE_VERSION} for 64 bit"
	----------------------------------------------

	cd "${WINE_BUILD_ROOT}/wine-64-build"
	
	./configure --prefix=$TARGET_DIR \
		--prefix=${WINE_TARGET_DIR_64}/ \
		--libdir=${WINE_TARGET_LIB_DIR_64} \
		--with-x \
		--with-gstreamer \
		--enable-win64

	make depend
	make

	echo "Installing Wine 64 bit"
	make install

	EOF

}

install_prereqs()
{

	# Test OS first, so we can allow configuration on multiple distros
	OS=$(lsb_release -si)

	case $OS in

		Arch)
			PKGS="\
			giflib                lib32-giflib \
			libpng                lib32-libpng \
			gnutls                lib32-gnutls \
			libxinerama           lib32-libxinerama \
			libxcomposite         lib32-libxcomposite \
			libxmu                lib32-libxmu \
			libxxf86vm            lib32-libxxf86vm \
			libldap               lib32-libldap \
			mpg123                lib32-mpg123 \
			openal                lib32-openal \
			v4l-utils             lib32-v4l-utils \
			libpulse              lib32-libpulse \
			alsa-lib              lib32-alsa-lib \
			libxcomposite         lib32-libxcomposite \
			mesa                  lib32-mesa \
			mesa-libgl            lib32-mesa-libgl \
			libcl                 lib32-libcl \
			libxslt               lib32-libxslt \
			gst-plugins-base-libs lib32-gst-plugins-base-libs \
			samba \
			opencl-headers"

			for PKG in ${PKGS}; 
			do

				sudo pacman -S --noconfirm ${PKG}

			done

		;;

		*)
		echo "Unsupported OS!"
		exit 1
		;;

	esac


}


# source options

while getopts ":v:h:" opt; do
	case $opt in

		v)
		if [[ -n "$2" ]]; then
			WINE_VERSION=$2
		else
			echo -e "ERROR: You must specify a wine version!.\n" >&2
			exit 1
		fi
		;;

		h)
		# TODO: help file
		:
		;;

		\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;

		:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;

	esac
done

main()
{

	# Install prereqs based on OS
	#install_prereqs

	# just build wine for now
	build_wine

}
