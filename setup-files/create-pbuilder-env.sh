#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:		create-pbuilder-env.sh
# Script Ver:		0.5.5
# Description:		Create buld environment for testing and building packages
# Usage:		create-pbuilder-env.sh [dist] [arch] [keyring]
#
# Notes:		For targets, see .pbuilderrc
# -------------------------------------------------------------------------------

# source arguments
# set var targets
export DIST="$1"
export ARCH="$2"
export KEYRING="$3"
export BETA_FLAG="false"
export BASETGZ="$HOME/pbuilder"
export BASEDIR="$HOME/pbuilder"

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

#####################################
# PBUILDER environement creation
#####################################

# Warn if DIST is blank
if [[ "$DIST" == "" ]]; then

	clear
	cat<<- EOF
	
	==ERROR==
	You must specify a distribution as an argument.
	type './create-pbuilder-env --help'
	
	EOF
	
fi

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

main()
{
	
	# set keyrings based on ARCH
	# For specifying arch, see: http://pbuilder.alioth.debian.org/#amd64i386
	case "$DIST" in
	
		alchemist|alchemist_beta|brewmaster|brewmaster_beta)
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
		DEBOOTSTRAPOPTS="--debootstrapopts --keyring=$KEYRING"
	        ;;
	
	        wheezy|jessie|stretch|sid)
		KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
		DEBOOTSTRAPOPTS="--debootstrapopts --keyring=$KEYRING"
	        ;;

		trusty|vivid|willy)
		KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
		DEBOOTSTRAPOPTS="--debootstrapopts --keyring=$KEYRING"
	        ;;

	        *)
	        # use steamos as default
		KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"
		DEBOOTSTRAPOPTS="--debootstrapopts --keyring=$KEYRING"
		;;
		
	esac
	
	echo -e "==> Options set:\n"
	sleep 2s
	
	cat<<- EOF
	
	DIST="$DIST"
	ARCH="$ARCH"
	KEYRING="$KEYRING"
	BETA_FLAG="false"
	BASETGZ="$BASETGZ"
	BASEDIR="$BASEDIR"

	EOF
	
	
	echo -e "==> Creating pbuilder environment\n"
	sleep 2s
	
	# setup dist base
	# test if final tarball was built
	if ! sudo ARCH=$ARCH DIST=$DIST BASETGZ=$BASETGZ BASEDIR=$BASEDIR \
		pbuilder create $DEBOOTSTRAPOPTS; then
	
		echo -e "\n${DIST} environment encountered a fatal error! Exiting."
		sleep 15s
		exit 1

	fi

	# test if final tarball was built
	if [[ -f "/var/cache/pbuilder/$DIST-base.tgz" ]]; then
	
		echo -e "\n${DIST} environment created successfully!"
	
	else
	
		echo -e "\n${DIST} environment creation FAILED! Exiting in 15 seconds"
		sleep 15s
		exit 1
	fi

}

# start main
main
