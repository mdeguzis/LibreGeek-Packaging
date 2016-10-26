#!/bin/bash
# -------------------------------------------------------------------------------
# Author: 	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/LibreGeek-Packaging
# Scipt Name:	build-arch-linux-chroot.sh
# Script Ver:	0.1.1
# Description:	Builds a clean x86_64 or i686 chroot for Arch Linux
#
# Usage:	sudo ./build-test-chroot.sh [type] [release] [arch]
#
# See: also:	https://wiki.archlinux.org/index.php/DeveloperWiki:Building_in_a_Clean_Chroot
#		https://wiki.archlinux.org/index.php/Building_32-bit_packages_on_a_64-bit_system
# -------------------------------------------------------------------------------

prepare_environment()
{

	# install needded packages
	PKGs="devtools devscripts arch-install-scripts"
	
	for PKG in ${PKGs};
	do

		echo -e "Installing: "${PKG}""

		if pacman -S ${PKG} &> /dev/null; then

			echo -e "Package: ${PKG} [OK]"

		else

			# echo and exit if package install fails
			echo -e "Package: ${PKG} [FAILED] Exiting..."
			exit 1

		fi

	done

	# Create needed dirs
	CHROOT_DIR="${HOME}/chroot-${ARCH}"
	
	if [[ -d "${CHROOT_DIR}" ]]; then 

		echo -e "\nERROR: chroot directory ${CHROOT_DIR} is taken. Please choose an alternate."
		sleep 0.2s
		unset CHROOT_DIR
		read -erp "Path: " CHROOT_DIR

	else

		mkdir -p "${CHROOT_DIR}"

	fi

build_chroot()
{

	# Set vars
	REPOS="base base-devel"
	CHROOT_DIR_ROOT="${CHROOT_DIR}/root"

	cd ${CHROOT_DIR}"

	# Gather conf files and  build chroot

	if [[ "${ARCH}" == "x86_64" ]]; then

		# This conf file is still in [testing], so pull from git
		wget "https://raw.githubusercontent.com/falconindy/devtools/master/makepkg-i686.conf" -q -nc --show-progress

		# copy in pacman.conf from /etc/
		cp "/etc/pacman.conf" "${CHROOT_DIR}"

		# Modify arch
		sed -i 's/Architecture = auto/Architecture = i686/' "${CHROOT_DIR}/pacman.conf"

		# set chroot options
		PACMAN_CONF="${CHROOT_DIR}/pacman.conf"
		MAKEPKG_CONF="${CHROOT_DIR}/makepkg.conf"

	elif [[ "${ARCH}" == "i686" ]]; then

		# set chroot options
		PACMAN_CONF="/etc/pacman.conf"
		MAKEPKG_CONF="/etc/makepkg.conf"

	else

		echo -e "\nERROR:\nOperation not supported!
		sleep 2s && exit 1

	fi

	echo -e "\n==> Building Chroot\n"

	# build chroot
	if sudo mkarchroot -C ${PACMAN_CONF} -M  ${MAKEPKG_CONF} ${CHROOT_DIR_ROOT} ${REPOS}; then

	else

		echo -e "\nERROR:\nFailed to build chroot!

	fi

}

update_chroot()
{

	echo -e "\n==> Updating Chroot\n"
	
	arch-nspawn "${CHROOT_DIR_ROOT}" -Syu

	echo -e "\nDone!"

}

main ()
{

	# prepare environment
	prepare_environment

	# build chroot
	build_chroot


}

############################
# source options
############################

while :; do
	case $1 in

		--arch|-a)
			if [[ -n "$2" ]]; then
				ARCH=$2
				shift
			else
				echo -e "ERROR: This option requires an argument.\n" >&2
				exit 1
			fi
			;;

		--build|-b)
			build_chroot
			update_chroot
			;;

		--update|-u)
			if [[ -n "$2" ]]; then
				CHROOT_DIR=$2
				shift
			else
				echo -e "ERROR: Please specify the path to your chroot.\n" >&2
				exit 1
			fi
			
			update_chroot
			;;

		--help|-h)
			cat<<-EOF

			Usage:		./build-arch-linux-chroot.sh [options]

			Options:
					--arch|-a		Specify arch
					--build|-b		Build chroot
					--update|-u		Update chroot

			arch options:
					x86_64
					i686

			EOF
			exit
			;;

		--)
			# End of all options.
			shift
			break
			;;

		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;

		*)
			# no more options
			break
			;;

	esac

	# shift args
	shift

done

################################
# Main
################################

# start main
main
