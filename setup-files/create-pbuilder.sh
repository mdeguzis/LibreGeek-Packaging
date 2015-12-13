#!/bin/bash

#####################################
# PBUILDER environement creation
#####################################

# set var target
DIST="brewmaster"
KEYRING="/usr/share/keyrings/valve-archive-keyring.gpg"

# setup dist base
if sudo DIST=$DIST pbuilder create --debootstrapopts --keyring=${KEYRING}; then

	echo -e "\n${target} environment created successfully!"

else

	echo -e "\n${target} environment creation FAILED! Exiting in 15 seconds"
	sleep 15s
	exit 1
fi

# create directory for dependencies
mkdir -p "/home/$USER/${dist_choice}-packaging/deps"
