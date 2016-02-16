#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:		pbuilder-wrapper.sh
# Script Ver:		0.5.5
# Description:		Wrapper for working with pbuilder
# Usage:		pbuilder-wrapper.sh [OPERATION] [dist] [arch] [keyring]
#
# Notes:		For targets, see .pbuilderrc
# -------------------------------------------------------------------------------

# source arguments
export OPERATION="$1"
export DIST="$2"
export ARCH="$3"
export KEYRING="$4"

# Set ARCH fallback
if [[ "$ARCH" == "" ]]; then

	ARCH=$(dpkg --print-architecture)
	
fi

# Set pbuilder-specific vars
export BETA_FLAG="false"
export BASE_DIR="${HOME}/pbuilder"
export BASE_TGZ="${BASE_DIR}/${DIST}-${ARCH}-base.tgz"

show_help()
{
	
	cat<<- EOF
	------------------------------------------------
	HELP
	------------------------------------------------
	See 'man pbuilder' or 'sudo pbuilder' for help
	
	Create:
	./create-pbuilder-env.sh [dist] [arch]
	
	Update:
	pbuilder --update --distribution $DIST
	
	Build:
	pbuilder --build 
	
	pbuilder --clean
	Cleans the temporal build directory.
	
	For distributions, see ~/.pbuilderrc
	
	EOF
	
}

set_creation_vars()
{
	
	# set var targets
	
	# set base DIST if requesting a beta
	if [[ "${DIST}" == "brewmaster_beta" || "${DIST}" == "alchemist_beta" ]]; then
	
		# Set DIST
		DIST=$(sed "s|_beta||g" <<<${DIST}) 
		BETA_FLAG="true"
		
		# Set extra packages to intall
		# Use wildcard * to replace the entire line
		PKGS="steamos-beta-repo wget ca-certificates"
		sed -i "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "$HOME/.pbuilderrc"
		sudo sed -i "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "/root/.pbuilderrc"
		
	else
	
		# Set extra packages to intall
		# Use wildcard * to replace the entire line
		# None for now
		PKGS="wget ca-certificates"
		sed -i "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "$HOME/.pbuilderrc"
		sudo sed -i "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=\"$PKGS\"|" "/root/.pbuilderrc"
		
	fi
	
	echo -e "==> Options set:\n"
	
	cat<<- EOF
	
	DIST="$DIST"
	ARCH="$ARCH"
	KEYRING="$KEYRING"
	BETA_FLAG="false"
	BASETGZ="$BASE_TGZ"
	BASEDIR="$BASE_DIR"

	EOF
	sleep 2s
	
	
}

run_pbuilder()
{
	
	if [[ "$PROCEED" == "true" ]]; then

		# Process actions, exit on fatal error
		if ! sudo DIST=$DIST pbuilder $OPERATION $OPTS; then
		
			echo -e "\n${DIST} environment encountered a fatal error! Exiting."
			sleep 3s
			exit 1
			
		fi
	
	else
	
		cat<<- EOF
		Invalid command...
		------------------------------
		Valid commands are:
		------------------------------
		create
		update
		build
		clean
		login
		login-save (--save-after-login)
		execute
		
		EOF
		exit 1

fi
	
}

main()
{
	
	# set options
	# For specifying arch, see: http://pbuilder.alioth.debian.org/#amd64i386
	case "$DIST" in
	
		alchemist|alchemist_beta|brewmaster|brewmaster_beta)
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
	        ;;
	
	        wheezy|jessie|stretch|sid)
		KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
	        ;;

		trusty|vivid|willy)
		KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
	        ;;

	        *)
	        # use steamos as default
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
		;;
		
	esac
	
	# Process $OPERATION
	case $OPERATION in
		
		create)
		PROCEED="true"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
		set_creation_vars
		run_pbuilder
		;;
		
		login)
		PROCEED="true"
		OPTS="--basetgz $BASE_TGZ"
		run_pbuilder
		;;
		
		login-save)
		PROCEED="true"
		OPERATION="login"
		OPTS="--basetgz $BASE_TGZ --save-after-login"
		run_pbuilder
		;;

		update|build|clean|login|execute)
		PROCEED="true"
		OPTS="--basetgz $BASE_TGZ --architecture $ARCH --debootstrapopts --keyring=$KEYRING"
		;;

	esac
	

}

# start main
main
