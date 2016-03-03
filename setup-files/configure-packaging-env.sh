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

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	sudo apt-get install -y --force-yes pbuilder libselinux1:i386 lsb-release bc devscripts
	
elif [[ "${OS}" == "Arch" ]]; then

	# Get pacaur deps 
	sudo pacman -S expac yajl bash-completion
	
	# packages in the main repos
	sudo pacman -S bc devscripts
	
	# install pacaur if not installed
	if ! pacaur -Qs pacaur; then
	
		# Install pacaur
		wget "https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz" -q -nc --show-progress
		tar zxvf pacaur.tar.gz
		cd pacaur && makepkg
		sudo pacman -U pacaur*.pkg.tar.xz
		
	fi

	# Finally, get build tools and pbuilder-ubuntu
	# Pass -S to invoke pacman
	pacaur -S pbuilder-ubuntu apt debian-archive-keyring

else

	echo -e "\nUnsupported OS/Distro! Exiting...\n"
	exit 1
	
fi

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
sed -i '/##### DEBIAN PACKAGING SETUP #####/,/##### END DEBIAN PACKAGING SETUP #####/d' "$HOME/.bashrc"

cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"

echo -e "\nSeting info for .bashrc"
sleep 2s

read -erp "Email: " EMAIL
read -erp "Maintainer full name: " FULLNAME
read -erp "GitHub username: " GITUSER
sed -i "s|EMAIL_TEMP|$EMAIL|" "$HOME/.bashrc"
sed -i "s|FULLNAME_TEMP|$FULLNAME|" "$HOME/.bashrc"

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

# source bashrc for this session
source $HOME/.bashrc
