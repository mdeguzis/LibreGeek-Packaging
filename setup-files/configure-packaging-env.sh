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

export scriptdir=$(pwd)
export steamos_tools_configs="$HOME/.config/SteamOS-Tools"

clear
echo -e "==> Installing basic packages"
sleep 2s

##################################################
# Base packages
#################################################

sudo apt-get install -y --force-yes build-essential autoconf automake and \
autotools-dev debhelper dh-make devscripts fakeroot git lintian patch patchutils \
pbuilder perl python quilt xutils-dev dh-make devscripts pbuilder

#################################################
# Create directories
#################################################

echo -e "\n==> Adding needed directories"
sleep 2s

dirs="${steamos_tools_configs}"

for dir in ${dirs};
do
	if [[ ! -d "${dir}" ]]; then
	
		mkdir -p "${dir}"
	
	fi
	
done

####################################################################
# Dot files
####################################################################

echo -e "\n==> Adding and configuring dotfiles"
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
cp "$scriptdir/.devscripts" "$HOME"

# GitHub Setup

git_user_test=$(git config --global user.name)
git_email_test=$(git config --global user.email)

if [[ "$git_user_test" == "" && "$git_email_test" == "" ]]; then

        echo -e "\nSeting info for Git config\n"
        sleep 2s
        
        read -erp "Git username: " GITUSER
        read -erp "Git email: " GITEMAIL
        git config --global user.name "${GITUSER}"
        git config --global user.email "${GITEMAIL}"
        
else

        echo -e "\nGit email/user already set, reset?"
        read -erp "Choice [y/n]: " git_reset
        
        if [[ "$git_reset" == "y" ]]; then

                read -erp "Git username: " GITUSER
                read -erp "Git email: " GITEMAIL
                git config --global user.name "${GITUSER}"
                git config --global user.email "${GITEMAIL}"
        
        fi

fi

#################################################
# Other configuration files
#################################################

echo -e "\n==> Adding other configuration files"
sleep 2s

cp "$scriptdir/repo-exclude.txt" "${steamos_tools_configs}"
cp "$scriptdir/repo-include.txt" "${steamos_tools_configs}"

#################################################
# Pbuilder
#################################################

# setup pbuilder
echo -e "\n==> Configuring pbuilder\n"
sleep 2s

./setup-pbuilder.sh

#################################################
# Cleanup
#################################################

# source bashrc
. $HOME/.bashrc
