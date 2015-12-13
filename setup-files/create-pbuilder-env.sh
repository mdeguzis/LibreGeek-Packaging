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

# if ARCH is blank, use x86_64 as a default
if [[ "$ARCH" == "" ]]; then

	ARCH="x86_64"
	
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
	
	
	# setup dist base
	if sudo DIST=$DIST pbuilder create --debootstrapopts \
	--keyring=${KEYRING} --arch=${ARCH}; then
	
		echo -e "\n${target} environment created successfully!"
	
	else
	
		echo -e "\n${target} environment creation FAILED! Exiting in 15 seconds"
		sleep 15s
		exit 1
	fi
	
	# create directory for dependencies
	mkdir -p "/home/$USER/${DIST}-packaging/deps"

}

# start main
main
