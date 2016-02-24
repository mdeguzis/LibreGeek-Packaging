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

clear
echo -e "==> Installing basic packages"
sleep 2s

##################################################
# Base packages
#################################################

# libselinux1:i386 on the host machine is needed for some reason on 32 bit chroots
# See: https://github.com/ProfessorKaos64/SteamOS-Tools/issues/125
sudo apt-get install -y --force-yes pbuilder libselinux1:i386

#################################################
# Create directories
#################################################

echo -e "\n==> Adding needed directories"
sleep 2s

steamos_tools_configs="$HOME/.config/SteamOS-Tools"
pbuilder_home="$HOME/pbuilder"

dirs="${steamos_tools_configs} ${pbuilder_home=}"

for dir in ${dirs};
do
	if [[ ! -d "${dir}" ]]; then

		mkdir -p "${dir}"

	fi

done

#################################################
# Dot files
#################################################

echo -e "\n==> Adding and configuring dotfiles"
sleep 2s

# .bashrc

bashrc_test_start=$(grep "##### DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")
bashrc_test_end=$(grep "##### END DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")

# Reset setup for incoming vars
sed -i '/"##### DEBIAN PACKAGING SETUP #####/,/##### END DEBIAN PACKAGING SETUP #####/d' "$HOME/.bashrc"

cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"

echo -e "Seting info for .bashrc"
sleep 2s

read -erp "Email: " EMAIL
read -erp "Maintainer full name: " FULLNAME
read -erp "GitHub username: " GITUSER
sed -e "s|EMAIL|$EMAIL|" "$HOME/.bashrc"
sed -e "s|FULLNAME|$FULLNAME|" "$HOME/.bashrc"


# Set github vars
git config --global user.name "${NAME}"
git config --global user.email "${GITUSER}"

# Setup Quilt rc file for dpkg
cp "$scriptdir/.quiltrc-dpkg" "$HOME"
cp "$scriptdir/.quiltrc" "$HOME"

# devscripts
cp "$scriptdir/.devscripts" "$HOME"

#################################################
# Other configuration files
#################################################

echo -e "\n==> Adding other configuration files"
sleep 2s

cp "$scriptdir/repo-exclude.txt" "${steamos_tools_configs}"
cp "$scriptdir/repo-include.txt" "${steamos_tools_configs}"
cp "$scriptdir/repo-filter.txt" "${steamos_tools_configs}"

#################################################
# Pbuilder
#################################################

# setup pbuilder
echo -e "\n==> Configuring pbuilder\n"
sleep 2s

./setup-pbuilder.sh

# copy wrapper script to bin for easy access
sudo cp pbuilder-wrapper.sh /usr/bin/pbuilder-wrapper

#################################################
# Cleanup
#################################################

# source bashrc
. $HOME/.bashrc
