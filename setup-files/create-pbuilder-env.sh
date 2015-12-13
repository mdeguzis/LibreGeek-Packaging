#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:			https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:		create-pbuilder-env.sh
# Script Ver:		0.1.3
# Description:		Create buld environment for testing and building packages
# Usage:		create-pbuilder-env.sh [dist] [arch] [keyring]
#
# Notes:		For targets, see .pbuilderrc
# -------------------------------------------------------------------------------

# source arguments
# set var target
DIST="$1"
ARCH="$2"
KEYRING="$3"

#####################################
# PBUILDER environement creation
#####################################

# Warn if DIST is blank
if [[ "$DIST" == "" ]]; then

	clear
	echo -e "\n==ERROR==\nYou must specify a distribution as an argument."
	echo -e "type './create-pbuilder-env --help'"
	
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
	
	pbuiler_create="sudo DIST=$DIST pbuilder create --debootstrapopts \
	--keyring=${KEYRING} --architecture=${ARCH}"
	
	# setup dist base
	if ${pbuilder_create}; then
	
		echo -e "\n${target} environment created successfully!"
	
	else
	
		echo -e "\n${target} environment creation FAILED! Exiting in 15 seconds"
		sleep 15s
		exit 1
	fi
	
	# create directory for dependencies
	mkdir -p "/home/$USER/${DIST}-packaging/deps"

}
