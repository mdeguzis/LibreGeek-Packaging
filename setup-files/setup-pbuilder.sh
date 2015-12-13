
#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:		        https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:   	build-pbuilder-env.sh
# Script Ver:		0.1.9
# Description:		Create buld environment for testing and building packages
# Usage:		./build-pbuilder-env.sh [distribution] [arch]
#
# Notes:          	For targets, see .pbuilderrc in this directory
# -------------------------------------------------------------------------------

#####################################
# Dependencies
#####################################

echo -e "\n==> Installing depedencies for packaging and testing\n"
sleep 2s

sudo apt-get install -y build-essential fakeroot devscripts cowbuilder pbuilder debootstrap

#####################################
# PBUILDER setup
#####################################

DIST="$1"
ARCH="$2"

# set the /var/cache/pbuilder/result directory writable by your user account.
sudo chmod u+w /var/cache/pbuilder/result

# create a directory, e.g. /var/cache/pbuilder/hooks, writable by the user, to place hook scripts in.
sudo mkdir -p /var/cache/pbuilder/hooks
sudo chown $USER:$USER /var/cache/pbuilder/hooks

# copy files based of pwd
touch "$HOME/.pbuilderrc"
sudo touch "/root/.pbuilderrc"
cp .pbuilderrc "$HOME/.pbuilderrc"
sudo cp .pbuilderrc "/root/.pbuilderrc"

#####################################
# PBUILDER environement creation
#####################################

# set vars

DISTS="$DIST" \
ARCHS="$ARCH" \
BUILDER="pdebuild" \
PBUILDER_BASE="/home/$USER/${target}-pbuilder/"

# setup dist base
if sudo pbuilder create; then

	echo -e "\n${target} environment created successfully!"
	
else 

	echo -e "\n${target} environment creation FAILED! Exiting in 15 seconds"
	sleep 15s
	exit 1
fi
	
# create directory for dependencies
mkdir -p "/home/$USER/${dist_choice}-packaging/deps"


