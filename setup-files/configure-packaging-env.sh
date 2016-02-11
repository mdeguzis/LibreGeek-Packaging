#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	configure-packaging-env.sh
# Script Ver:	2.1.1
# Description:	Installs basic packaging tools suggested by the Debian
#               maintainers guide and configures various packaging options
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	./configure-packaging-env.sh
# -------------------------------------------------------------------------------

scriptdir=$(pwd)

clear
echo -e "==> Installing basic packages"
sleep 2s

##################################################
# Base packages
#################################################

sudo apt-get install -y --force-yes build-essential autoconf automake and \
autotools-dev debhelper dh-make devscripts fakeroot git lintian patch patchutils \
pbuilder perl python quilt xutils-dev dh-make devscripts

####################################################################
# Dot files
####################################################################

echo -e "\n==> Configuring dotfiles"
sleep 2s

# .bashrc (if exists)
bashrc_test_start=$(grep "##### DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")
bashrc_test_end=$(grep "##### END DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")

if [[ "$bashrc_test_start" == "" && "$bashrc_test_start" == "" ]]; then

        cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"
        
        echo -e "Seting info for .bashrc"
        sleep 2s
        
        read -erp "Email: " EMAIL
        read -erp "Full Name: " NAME
        sed -e "s|EMAIL|$EMAIL|" "$HOME/.bashrc"
        sed -e "s|NAME|$NAME|" "$HOME/.bashrc"

fi

# Setup Quilt rc file for dpkg
cp "$scriptdir/.quiltrc-dpkg" "$HOME"
cp "$scriptdir/.quiltrc" "$HOME"

# devscripts
cp "$scriptdir/.quiltrc" "$HOME"

####################################################################
# Pbuilder
####################################################################

# setup pbuilder
echo -e "\n==> Configuring pbuilder"
sleep 2s

./setup-pbuilder.sh

####################################################################
# Cleanup
####################################################################

# source bashrc
. $HOME/.bashrc

