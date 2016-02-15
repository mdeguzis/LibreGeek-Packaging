#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:		create-pbuilder-env.sh
# Script Ver:		0.3.5
# Description:		Create buld environment for testing and building packages
# Usage:		create-pbuilder-env.sh [dist] [arch] [keyring]
#
# Notes:		For targets, see .pbuilderrc
# -------------------------------------------------------------------------------

# source arguments
# set var target
export DIST="$1"
export ARCH="$2"
export KEYRING="$3"
export BETA_FLAG="false"

# set base DIST if requesting a beta
if [[ "${DIST}" == "brewmaster_beta" || "${DIST}" == "alchemist_beta" ]]; then

	# Set DIST
	DIST=$(sed "s|_beta||g" <<<${DIST}) 
	BETA_FLAG="true"
	
	# Set extra packages to intall
	# Use wildcard * to replace the entire line
	sed "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=bc debian-archive-keyring steamos-beta-repo|" "$HOME/.pbuilderrc"
	sudo sed "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=bc debian-archive-keyring steamos-beta-repo|" "/root/.pbuilderrc"
	
else

	# Set extra packages to intall
	# Use wildcard * to replace the entire line
	sed "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=bc debian-archive-keyring|" "$HOME/.pbuilderrc"
	sudo sed "s|^.*EXTRAPACKAGES.*|EXTRAPACKAGES=bc debian-archive-keyring|" "/root/.pbuilderrc"
	
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
	case "$DIST" in
	
		alchemist|alchemist_beta|brewmaster|brewmaster_beta)
		KEYRING_VALVE="/usr/share/keyrings/valve-archive-keyring.gpg"
		OPTS="--debootstrapopts --keyring=${KEYRING_VALVE}"
	        ;;
	
	        wheezy|jessie|stretch|sid)
		KEYRING_DEBIAN="/usr/share/keyrings/debian-archive-keyring.gpg"
		OPTS="--debootstrapopts --keyring=${KEYRING_DEBIAN}"
	        ;;

		trusty|vivid|willy)
		KEYRING_UBUNTU="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
		OPTS="--debootstrapopts --keyring=${KEYRING_UBUNTU}"
	        ;;

	        *)
	        # use steamos as default
		KEYRING_VALVE="/usr/share/keyrings/valve-archive-keyring.gpg"
		OPTS="--debootstrapopts --keyring=${KEYRING_VALVE}"
		;;
		
	esac

	# setup dist base
	# test if final tarball was built
	if ! sudo DIST=$DIST pbuilder create $OPTS; then
	
		echo -e "\n${DIST} environment encountered a fatal error! Exiting."
		sleep 15s
		exit 1

	fi

	# test if final tarball was built
	if [[ -f "/var/cache/pbuilder/${DIST}-base.tgz" ]]; then
	
		echo -e "\n${DIST} environment created successfully!"
	
	else
	
		echo -e "\n${DIST} environment creation FAILED! Exiting in 15 seconds"
		sleep 15s
		exit 1
	fi
	
	# create directory for dependencies
	mkdir -p "/home/$USER/${DIST}-packaging/deps"

}

# start main
main

