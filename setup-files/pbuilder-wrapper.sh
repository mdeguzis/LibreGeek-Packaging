#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:		pbuilder-wrapper.sh
# Script Ver:		0.5.9
# Description:		Wrapper for working with pbuilder
# Usage:		pbuilder-wrapper.sh [OPERATION] [dist] [arch] [keyring]
#			pbuilder-wrapper.sh --help
# Notes:		For targets, see .pbuilderrc
# -------------------------------------------------------------------------------

# source arguments
export OPERATION="$1"
export DIST="$2"
export ARCH="$3"
export KEYRING="$4"

# Halt if help requested
if [[ "${OPERATION}" == "--help" ]]; then

	show_help

fi


show_help()
{

	clear
	cat<<- EOF
	------------------------------------------------
	HELP
	------------------------------------------------
	See 'man pbuilder' or 'sudo pbuilder' for help
	DIST is required.

	pbuilder-wrapper [ACTION][DIST][ARCH][KEYRING]

	Available actions:

	create
	update
	build
	clean
	login
	login-save (--save-after-login)
	execute

	EOF
	exit 1


}

set_vars()
{

	# Set ARCH fallback
	if [[ "${ARCH}" == "" ]]; then

		ARCH=$(dpkg --print-architecture)

	fi

	# Set pbuilder-specific vars
	export BETA_FLAG="false"

	# root on SteamOS is small, divert cache dir if applicable
	# Also adjust for other locations, due to limited space on root
	OS=$(lsb_release -si)

	if [[ "${OS}" == "SteamOS" ]]; then

		BASE_DIR="${HOME}/pbuilder"
		BASE_TGZ="${BASE_DIR}/${DIST}-${ARCH}-base.tgz"

	else

		BASE_DIR="/var/cache/pbuilder"
		BASE_TGZ="${BASE_DIR}/${DIST}-${ARCH}-base.tgz"

	fi

	# set var targets

	# set base DIST if requesting a beta
	if [[ "${DIST}" == "brewmaster_beta" || "${DIST}" == "alchemist_beta" ]]; then

		# Set DIST
		DIST=$(sed "s|_beta||g" <<<${DIST})
		BETA_FLAG="true"

		# Set extra packages to intall
		# Use wildcard * to replace the entire line
		PKGS="steamos-beta-repo wget ca-certificates aptitude"
		sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "${HOME}/.pbuilderrc"
		sudo sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "/root/.pbuilderrc"

	else

		# Set extra packages to intall
		# Use wildcard * to replace the entire line
		# None for now

		if [[ "${ARCH}" == "i386" ]]; then

			PKGS="wget ca-certificates aptitude"
			sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "${HOME}/.pbuilderrc"
			sudo sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "/root/.pbuilderrc"	

		else

			PKGS="wget ca-certificates aptitude"
			sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "${HOME}/.pbuilderrc"
			sudo sed -i "s|.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "/root/.pbuilderrc"
	
		fi

	fi

	# Only show detailed info if creating the chroot
	if [[ "${OPERATION}" == "create" ]]; then

		cat<<- EOF

		-----------------------------
		Options passed:
		-----------------------------
		DIST="${DIST}"
		ARCH="${ARCH}"
		KEYRING="${KEYRING}"
		BETA_FLAG="false"
		BASE_TGZ="${BASE_TGZ}"
		BASE_DIR="${BASE_DIR}"
		APTCACHE="${APTCACHE}"
		EXTRA PACKAGES: "${PKGS}"
		-----------------------------

		Are the above options OK?
		EOF

		read -erp "Confirm [y/n]: " create_choice

		if [[ "${create_choice}" != "y" ]]; then

			echo -e "Exiting script\n"
			exit 1

		fi

	fi

}

run_pbuilder()
{

	if [[ "$PROCEED" == "true" ]]; then

		# Process actions, exit on fatal error
		if ! ARCH=${ARCH} DIST=${DIST} sudo pbuilder ${OPERATION} ${OPTS}; then

			echo -e "\n${DIST} environment encountered a fatal error! Exiting."
			sleep 3s
			exit 1

		fi

	else

		show_help
	fi

}

main()
{

	# set options
	# For specifying arch, see: http://pbuilder.alioth.debian.org/#amd64i386
	case "${DIST}" in

		alchemist|alchemist_beta|brewmaster|brewmaster_beta)
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
	        ;;

	        wheezy|jessie|stretch|sid)
		KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
	        ;;

		trusty|vivid|willy)
		KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
	        ;;

	        *)
	        # use steamos as default
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
		;;

	esac

	# Process ${OPTS}
	case ${OPERATION} in

		create)
		set_vars
		PROCEED="true"
		OPTS="--basetgz ${BASE_TGZ} --aptcache ${APTCACHE} --architecture ${ARCH} \
		--debootstrapopts --keyring=${KEYRING}"
		run_pbuilder
		;;

		login)
		set_vars
		PROCEED="true"
		OPTS="--basetgz ${BASE_TGZ} --aptcache ${APTCACHE} "
		run_pbuilder
		;;

		login-save)
		set_vars
		PROCEED="true"
		OPERATION="login"
		OPTS="--basetgz ${BASE_TGZ} --aptcache ${APTCACHE} --save-after-login"
		run_pbuilder
		;;

		update|build|clean|execute)
		set_vars
		PROCEED="true"
		OPTS="--basetgz ${BASE_TGZ} --aptcache ${APTCACHE} --architecture ${ARCH} \
		--debootstrapopts --keyring=${KEYRING}"
		run_pbuilder
		;;

	esac


}

# start main
main
