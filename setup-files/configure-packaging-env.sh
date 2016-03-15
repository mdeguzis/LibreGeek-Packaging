#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	configure-packaging-env.sh
# Script Ver:	2.7.3
# Description:	Installs basic packaging tools suggested by the Debian
#               maintainers guide and configures various packaging options
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	./configure-packaging-env.sh
# -------------------------------------------------------------------------------

export scriptdir=$(pwd)

clear
echo -e "==> Installing basic packages\n"
sleep 2s

##################################################
# Base packages
##################################################

# libselinux1:i386 on the host machine is needed for some reason on 32 bit chroots
# See: https://github.com/ProfessorKaos64/SteamOS-Tools/issues/125

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)
MULTIARCH=$(dpkg --print-foreign-architectures | grep i386)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# add multiarch if it is missing
	if [[ "${MULTIARCH}" == "" ]]; then

		sudo dpkg --add-architecture i386
		echo -e "Updating for multiarch\n" 
		sleep 2s
		sudo apt-get update

	fi

	sudo apt-get install -y --force-yes pbuilder libselinux1 libselinux1:i386 \
	lsb-release bc devscripts sudo

elif [[ "${OS}" == "Arch" ]]; then

	# Default pacman options
	PACOPTS="--noconfirm --noprogressbar --needed"
	AUROPTS="--noconfirm --needed --noedit"

	# Get pacaur deps 
	sudo pacman -S ${PACOPTS} expac yajl bash-completion

	# packages in the main repos
	sudo pacman -Sa ${PACOPTS} bc

	# devscripts in the AUR is broken, so it was added to my repo and fixed:
	# https://github.com/ProfessorKaos64/arch-aur-packages

	git clone "https://github.com/ProfessorKaos64/arch-aur-packages"
	cd "arch-aur-packages/devscripts" || exit 1
	makepkg -s
	sudo pacman -U ${PACOPTS} "devscripts-2.16.1-1-any.pkg.tar.gz"
	cd ../..
	rm -rf "arch-aur-packages"

	# install pacaur if not installed
	if ! pacaur -Qs pacaur; then

		# Install pacaur
		wget "https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz" -q -nc --show-progress
		tar zxvf pacaur.tar.gz
		cd pacaur && makepkg
		sudo pacman -U ${PACOPTS} pacaur*.pkg.tar.xz

	else

		# just update pacaur target (don't reinstall if up to date)
		pacaur -Sa ${AUROPTS}

	fi

	# Finally, get build tools and pbuilder-ubuntu
	# Pass -S to invoke pacman
	pacaur -Sa ${AUROPTS} pbuilder-ubuntu apt debian-archive-keyring

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

dirs="${steamos_tools_configs}"

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

echo -e "\nReset .bashrc? setup?"
echo -e "This will remove GitHub, quilt, and host setups"
sleep 0.5s

# info may already be setup, allow people to ignore it.
read -erp "Choice [y/n]: " bashrc_choice

if [[ "${bashrc_choice}" == "y" ]]; then

	# Check for block of text
	bashrc_test_start=$(grep "##### DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")
	bashrc_test_end=$(grep "##### END DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")
	
	# Reset setup for incoming vars
	sed -i '/##### DEBIAN PACKAGING SETUP #####/,/##### END DEBIAN PACKAGING SETUP #####/d' "$HOME/.bashrc"
	
	cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"

fi

# Setup Quilt rc file for dpkg
cp "$scriptdir/.quiltrc-dpkg" "$HOME"
cp "$scriptdir/.quiltrc" "$HOME"

# devscripts
cp "$scriptdir/.devscripts" "$HOME"

# pbuilder
cp "$scriptdir/.pbuilderrc" "$HOME/"
sudo cp "$scriptdir/.pbuilderrc" "/root/"

#################################################
# GitHub Setup
#################################################

# Set github vars, only if they are missing

if [[ $(git config --global user.name) == "" ]]; then

	echo -e "Please set your GitHub username: "
	read -erp "Username: " GITUSER
	git config --global user.name "${GITUSER}"

else

	echo -e "GitHub global username set. Reset?"
	read -erp "Choice [y/n]: " reset_username

	if [[ "${reset_username}"  == "y" ]]; then

		echo -e "Please set your GitHub username: "
		read -erp "Username: " GITUSER
		git config --global user.name "${GITUSER}"

	fi

fi

# If bashrc was reset, we need to configure this

if grep "FULLNAME_TEMP" "$HOME/.bashrc"; then

	# Set bashrc information
	read -erp "Maintainer full name: " FULLNAME
	sed -i "s|FULLNAME_TEMP|$FULLNAME|" "$HOME/.bashrc"
	
fi

if [[ $(git config --global user.email) == "" ]]; then

	echo -e "Please set your GitHub email: "
	read -erp "Email: " GITEMAIL
	git config --global user.email "${GITEMAIL}"
	
	# set bashrc
	# If bashrc was not reset, this will have no affect
	sed -i "s|EMAIL_TEMP|$GITEMAIL|" "$HOME/.bashrc"

else

	echo -e "GitHub global email set. Reset?"
	read -erp "Choice [y/n]: " reset_email

	if [[ "${reset_email}"  == "y" ]]; then

		echo -e "Please set your GitHub email: "
		read -erp "Email: " GITEMAIL
		git config --global user.email "${GITEMAIL}"
		
		# set bashrc
		# If bashrc was not reset, this will have no affect
		sed -i "s|EMAIL_TEMP|$GITEMAIL|" "$HOME/.bashrc"

	fi

fi

##################################################
# Host / Network
#################################################

# Set a remote host/user if desired now.
# All build scripts will default to a set value in the script if this is not set

echo -e "\n==> Setting host/network information"

echo -e "\nSetup remote user/host for repository pool?"
echo -e "This is suggested if you are using a remote host"
read -erp "Choice [y/n]: " set_host_user

if [[ "${set_host_user}" == "y" ]]; then

	read -erp "Remote username: " REMOTE_USER_TEMP
	read -erp "Remote host: " REMOTE_HOST_TEMP
	read -erp "Remote port: " REMOTE_PORT_TEMP
	
	sed -i "s|REMOTE_USER_TEMP|$REMOTE_USER_TEMP|" "$HOME/.bashrc"
	sed -i "s|REMOTE_HOST_TEMP|$REMOTE_HOST_TEMP|" "$HOME/.bashrc"
	sed -i "s|REMOTE_PORT_TEMP|$REMOTE_PORT_TEMP|" "$HOME/.bashrc"

else
	
	# Set var to blank string so value inside build script is taken	
	sed -i "s|REMOTE_USER_TEMP|$EMAIL|" "$HOME/.bashrc"
	sed -i "s|REMOTE_HOST_TEMP|$FULLNAME|" "$HOME/.bashrc"
	sed -i "s|REMOTE_PORT_TEMP|22|" "$HOME/.bashrc"

fi

#################################################
# Other configuration files
#################################################

echo -e "\n==> Adding other configuration files"
sleep 2s

cp "$scriptdir/repo-exclude.txt" "${steamos_tools_configs}"
cp "$scriptdir/repo-include.txt" "${steamos_tools_configs}"
cp "$scriptdir/repo-filter.txt" "${steamos_tools_configs}"

#################################################
# Preferences
#################################################

# Editor
# Provided by sensible-utils, dependency of debianutils
select-editor

#################################################
# Pbuilder setup
#################################################

# setup pbuilder
echo -e "\n==> Configuring pbuilder\n"
sleep 2s

echo -e "Installing keyrings\n"
sleep 2s

# Set vars
valve_keyring="valve-archive-keyring_0.5+bsos3_all"

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# Setup common packages
	
	# Libregeek keyrings
	wget http://packages.libregeek.org/libregeek-archive-keyring-latest.deb -q --show-progress -nc
	wget http://packages.libregeek.org/steamos-tools-repo-latest.deb -q --show-progress -nc
	sudo dpkg -i libregeek-archive-keyring-latest.deb
	sudo dpkg -i steamos-tools-repo-latest.deb
	
	# cleanup
	rm -f steamos-tools-repo-latest.deb
	rm -f libregeek-archive-keyring-latest.deb
	rm -f valve-archive-keyring*.deb
	
	# update for keyrings
	
	echo -e "\nUpdating system for newly added keyrings\n"
	sleep 2s
	sudo apt-key update
	sudo apt-get update

elif [[ "${OS}" == "Arch" ]]; then

	
	# obtain keyring source for Valve archive keyring and convert it, not provided in AUR
	mkdir -p "$HOME/setup-temp" && cd "$HOME/setup-temp"
	wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/${valve_keyring}.deb" -q -nc --show-progress

	# Convert
	ar xv "${valve_keyring}.deb"
	tar -xvf data.tar.xz
	sudo cp "etc/apt/trusted.gpg.d/valve-archive-keyring.gpg" "/etc/apt/trusted.gpg.d/"
	sudo cp "usr/share/keyrings/valve-archive-keyring.gpg" "/usr/share/keyrings"
	
	# cleanup
	cd ..
	rm -rf "$HOME/setup-temp"

fi

# Setup Debian specific (such as the Valve keyring)
# This package is obviously in SteamOS already

if [[ "${OS}" == "Debian" ]]; then

	# Obtain valve keyring
	wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/${valve_keyring}.deb" -q --show-progress -nc 
	sudo dpkg -i "valve-archive-keyring_0.5+bsos3_all.deb"

fi

##########################
# Pbuilder folders
##########################

echo -e "\nAdding pbuilder folders"
sleep 1s

# root on SteamOS is small, divert cache dir if applicable
# Also adjust for other locations, due to limited space on root
OS=$(lsb_release -si)

if [[ "${OS}" == "SteamOS" ]]; then

	mkdir -p "${HOME}/pbuilder/${DIST}/aptcache/"
	cp -r "${scriptdir}/hooks" "$HOME/pbuilder/"
	
else

	sudo cp -r "${scriptdir}/hooks" "/var/cache/pbuilder/"

fi

##########################
# Extra setup
##########################

# IMPORTANT!
# For information, see: http://manpages.ubuntu.com/manpages/precise/man5/pbuilderrc.5.html

echo -e "\nAdding symlinks for /usr/share/debootstrap/scripts"
sleep 1s

# brewmaster
sudo ln -s "/usr/share/debootstrap/scripts/jessie" "/usr/share/debootstrap/scripts/brewmaster" 2> /dev/null
sudo ln -s "/usr/share/debootstrap/scripts/jessie" "/usr/share/debootstrap/scripts/brewmaster_beta" 2> /dev/null

# alchemist
sudo ln -s "/usr/share/debootstrap/scripts/wheezy" "/usr/share/debootstrap/scripts/alchemist" 2> /dev/null
sudo ln -s "/usr/share/debootstrap/scripts/wheezy" "/usr/share/debootstrap/scripts/alchemist_beta" 2> /dev/null

echo -e "\nFinishing up"
sleep 0.5s

# output help
cat <<-EOF

################################################################
Summary
################################################################
Creating:
sudo DIST=[DIST] ARCH=[ARCH] pbuilder [OPERATION]

Creation on SteamOS:
sudo -E DIST=[DIST] ARCH=[ARCH] pbuilder create

Operations:
[create|login|login|login --save-after-login|update]

EOF

#################################################
# Cleanup
#################################################

# source bashrc for this session
. $HOME/.bashrc
