#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	configure-packaging-env.sh
# Script Ver:	2.9.1
# Description:	Installs basic packaging tools suggested by the Debian
#               maintainers guide and configures various packaging options
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	./configure-packaging-env.sh
# -------------------------------------------------------------------------------

# Main vars
export scriptdir=$(pwd)
BASHRC_RESET="false"

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

	# Standard packages
	echo -e "\n==> Installing main packages\n"
	sleep 2s

	pkgs="pbuilder libselinux1 libselinux1:i386 lsb-release bc devscripts sudo screen pv"

	for pkg in ${pkgs};
	do

		if ! sudo apt-get install -yq --force-yes ${pkg}; then
		
			# echo and exit if package install fails
			echo -e "\n==ERROR==\nInstallation of ${pkg} failed! Exiting..."
			sleep 2s
			exit 1
		fi

	done
	
	# Open Build System
	#echo "\nInstalling Open Build System package\n"
	#sleep 2s

	#sudo cp "${scriptdir}/etc/apt/sources.list.d/osc.list" "/etc/apt/sources.list.d/"
	#apt-get update -y
	#apt-get install -y --force-yes osc


elif [[ "${OS}" == "Arch" ]]; then

	# Default pacman options
	PACOPTS="--noconfirm --noprogressbar --needed"
	AUROPTS="--noconfirm --needed --noedit"

	# Get pacaur deps
	sudo pacman -S ${PACOPTS} expac yajl

	# get main packages in the main repos for extra needs
	sudo pacman -S ${PACOPTS} bc

	# install pacaur if not installed
	if ! pacman -Qs pacaur; then

		# Install pacaur
		wget "https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz" -q -nc --show-progress
		tar zxvf pacaur.tar.gz
		cd pacaur && makepkg
		sudo pacman -U ${PACOPTS} pacaur*.pkg.tar.xz

	else

		# just update pacaur targets (don't reinstall if up to date)
		pacaur -Sa ${AUROPTS} pacaur apt

	fi
	

	# Finally, get build tools needed out of the AUR
	# Pass -S to invoke pacman
	pacaur -Sa ${AUROPTS} pbuilder-ubuntu debian-archive-keyring apt devscripts
	
	# Do we need custom AUR packages that are out of date?
	CUSTOM_AUR_PKGS="false"
	
	# OBS Open Build System
	# Disable this for now.

	#if [[ $(grep "openSUSE_Tools_Arch_Extra" "/etc/pacman.conf") == "" ]]; then
#
#		sudo su -c "echo '[openSUSE_Tools_Arch_Extra]' >> /etc/pacman.conf"
#		sudo su -c "echo 'SigLevel = Never' >> /etc/pacman.conf"
#		sudo su -c "echo 'Server = http://download.opensuse.org/repositories/openSUSE:/Tools/Arch_Extra/$arch' >> /etc/pacman.conf"

#		if [[ $(pacman -Qs osc) == "" ]]; then
#
#			sudo pacman -Syu
#			sudo pacman -S openSUSE_Tools_Arch_Extra/osc
#
#		fi

#	fi
	
	# <!> Evaluate packages that are broken or out of date in the AUR
	# <!> 'apt' in the AUR is out of date, so it was added to my repo and fixed
	# <!> 'devscripts' in the AUR is out of date, so it was added to my repo and fixed:
	# https://github.com/ProfessorKaos64/arch-aur-packages
	
	# Don't clone this repo if they are found
	# Not used right now, but keep if needed for the future
	if [[ "${CUSTOM_AUR_PKGS}" == "true" ]]; then

		git clone "https://github.com/ProfessorKaos64/arch-aur-packages"
		root_dir="${PWD}"
		aur_install_dir="${root_dir}/arch-aur-packages"
		my_arch_pkgs="devscripts"
		
		for pkgs in ${my_arch_pkgs};
		do

			cd "${aur_install_dir}/${pkg}" || exit 1
			makepkg -s
	
			# No 'else' logic here, we can't check for updates, no AUR of course.
			if ! sudo pacman -U ${PACOPTS} ${pkg}*.pkg.tar.gz; then
	
				echo "ERROR: Installation of ${pkg} failed. Exiting"
				exit 1
	
			fi

		done

	fi

	# Clean up manual AUR package installation directory
	cd "${root_dir}"
	rm -rf "arch-aur-packages"

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

#####################
# bashrc
#####################

# Reset setup? Check for headers
bashrc_test_start=$(grep "##### DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")
bashrc_test_end=$(grep "##### END DEBIAN PACKAGING SETUP #####" "$HOME/.bashrc")

if [[ "${bashrc_test_start}" != "" && "${bashrc_test_start}" != "" ]]; then

	echo -e "\nReset .bashrc? setup?"
	echo -e "This will remove GitHub, quilt, and host setups, etc."
	sleep 0.5s
	
	# info may already be setup, allow people to ignore it.
	
	read -erp "Choice [y/n]: " bashrc_choice
	
	if [[ "${bashrc_choice}" == "y" ]]; then
	
		# Reset setup for incoming vars
		sed -i '/##### DEBIAN PACKAGING SETUP #####/,/##### END DEBIAN PACKAGING SETUP #####/d' "$HOME/.bashrc"
		
		cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"
	
	fi
	
else

	# copy in template
	cat "$scriptdir/.bashrc" >> "$HOME/.bashrc"
	
fi

# Assess if TEMP vars exist, replace them
# Set bashrc information

if [[ $(grep "FULLNAME_TEMP" "${HOME}/.bashrc") != "" ]]; then

	read -erp "Maintainer full name: " FULLNAME_TEMP
	sed -i "s|FULLNAME_TEMP|$FULLNAME_TEMP|" "$HOME/.bashrc"

fi

if [[ $(grep "EMAIL_TEMP" "${HOME}/.bashrc") != "" ]]; then

	read -erp "GitHub Email: " EMAIL_TEMP
	sed -i "s|EMAIL_TEMP|$EMAIL_TEMP|" "$HOME/.bashrc"

fi

#####################
# Quilt
#####################

# Setup Quilt rc file for dpkg
cp "$scriptdir/.quiltrc-dpkg" "$HOME"
cp "$scriptdir/.quiltrc" "$HOME"

#####################
# devscripts
#####################

# devscripts
cp "$scriptdir/.devscripts" "$HOME"

#####################
# pbuilder
#####################

# pbuilder
cp "$scriptdir/.pbuilderrc" "$HOME/"
sudo cp "$scriptdir/.pbuilderrc" "/root/"

#################################################
# GitHub Setup
#################################################

# Set github vars, only if they are missing
# Since this is the global git config, it must be assessed
# seperately from the bashrc setup.

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

if [[ $(git config --global user.email) == "" ]]; then

	# The email may already by sourced during the bashrc setup, check
	if [[ ${EMAIL_TEMP} != "" ]]; then

		git config --global user.email "${EMAIL_TEMP}"

	else

		echo -e "Please set your GitHub email: "
		read -erp "Email: " GITEMAIL
		git config --global user.email "${GITEMAIL}"
		
	fi
	
else

	echo -e "GitHub global email set. Reset?"
	read -erp "Choice [y/n]: " reset_email

	if [[ "${reset_email}"  == "y" ]]; then

		echo -e "Please set your GitHub email: "
		read -erp "Email: " GITEMAIL
		git config --global user.email "${GITEMAIL}"

	fi

fi

##################################################
# Host / Network
#################################################

# Set a remote host/user if desired now.
# All build scripts will default to a set value in the script if this is not set

echo -e "\n==> Setting host/network information"


echo -e "\nSetup/Reset remote user/host for repository pool?"
echo -e "This is suggested if you are using a remote host"
read -erp "Choice [y/n]: " set_host_user

if [[ "${set_host_user}" == "y" ]]; then

	read -erp "Remote username: " REMOTE_USER_TEMP
	read -erp "Remote host: " REMOTE_HOST_TEMP
	read -erp "Remote port: " REMOTE_PORT_TEMP

	# Use wildcard to assume if it was set to something else before, clear it
	# when using double quotes here, you do not need to escape $ or =
	sed -i "s|REMOTE_USER.*|REMOTE_USER=\"${REMOTE_USER_TEMP}\"|" "$HOME/.bashrc"
	sed -i "s|REMOTE_HOST.*|REMOTE_HOST=\"${REMOTE_HOST_TEMP}\"|" "$HOME/.bashrc"
	sed -i "s|REMOTE_PORT.*|REMOTE_PORT=\"${REMOTE_PORT_TEMP}\"|" "$HOME/.bashrc"

else
	
	# Set var to blank string so value inside build script is taken	
	# Use wildcard to assume if it was set to something else before, clear it
	sed -i "s|REMOTE_USER.*|REMOTE_USER=\"\"|" "$HOME/.bashrc"
	sed -i "s|REMOTE_HOST.*|REMOTE_HOST=\"\"|" "$HOME/.bashrc"
	sed -i "s|REMOTE_PORT.*|REMOTE_PORT=\"\"|" "$HOME/.bashrc"

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

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	select-editor

	# disable this line in bashrc if it exists so it does not interfere:
	sed -i "s|export EDITOR=.*|#export EDITOR=\"\"|g" "$HOME/.bashrc"

else

	if [[ "${EDITOR}" == "" ]]; then

		echo "No editor currently set"
	
	else

		echo -e "\nCurrent editor set: ${EDITOR}\n"
		sleep 3s
		
	fi

	# List editors and set
	ls "/usr/bin" | grep -xE 'vi|vim|nano|emacs|gvim' && echo ""
	read -erp "Default editor to use: " EDITOR
	sed -i "s|EDITOR_TEMP|$EDITOR|" "$HOME/.bashrc"
	
fi

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
	
	# clean packages if a prior attempt was used or source files were manually removed
	sudo apt-get remove -yqq libregeek-archive-keyring* steamos-tools-repo* 
	
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

	rm -rf "${HOME}/pbuilder/hooks"
	mkdir -p "${HOME}/pbuilder/${DIST}/aptcache/"
	cp -r "${scriptdir}/hooks" "${HOME}/pbuilder/"

else

	sudo rm -rf "/var/cache/pbuilder/hooks"
	sudo cp -r "${scriptdir}/hooks" "/var/cache/pbuilder/"

fi

#################################################
# OpenSUSE - Open Build System setup
#################################################

##########################
# Extra setup
##########################

# IMPORTANT!
# For information, see: http://manpages.ubuntu.com/manpages/precise/man5/pbuilderrc.5.html

echo -e "\nAdding symlinks for /usr/share/debootstrap/scripts"
sleep 1s

# jessie-backports
sudo ln -s "/usr/share/debootstrap/scripts/jessie" "/usr/share/debootstrap/scripts/jessie-backports" 2> /dev/null

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

Creating a pbuilder chroot setup:
sudo -E DIST=[DIST] ARCH=[ARCH] pbuilder create

EOF

#################################################
# Cleanup
#################################################

# source bashrc for this session
. $HOME/.bashrc
