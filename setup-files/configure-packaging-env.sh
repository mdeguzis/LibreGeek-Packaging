#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	configure-packaging-env.sh
# Script Ver:	2.9.7
# Description:	Installs basic packaging tools suggested by the Debian
#               maintainers guide and configures various packaging options
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	./configure-packaging-env.sh
# -------------------------------------------------------------------------------

# Main vars
export SCRIPTDIR=$(pwd)
BASHRC_RESET="false"

cat<<-EOF

##################################################
LibreGeek Packaging Environment Setup Script
##################################################

EOF
sleep 2s

##################################################
# Base packages
##################################################

# libselinux1:i386 on the host machine is needed for some reason on 32 bit chroots
# See: https://github.com/ProfessorKaos64/SteamOS-Tools/issues/125

echo -e "==> Checking for multiarch\n" 

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)
MULTIARCH=$(dpkg --print-foreign-architectures | grep i386)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# add multiarch if it is missing
	if [[ "${MULTIARCH}" == "" ]]; then

		echo -e "Multiarch not found!"
		sudo dpkg --add-architecture i386
		echo -e "Updating for multiarch\n" 
		sleep 2s
		sudo apt-get update

	fi

	# Standard packages
	echo -e "==> Installing prerequisite packages\n"
	sleep 2s

	# Deboostrap was backport to include more scripts, specify version
	# We want to specify our version, more up to date
	# If not use available version
	
	if [[ -f "/etc/apt/sources.list.d/steamos-tools.list" ]]; then
	
		if sudo apt-get install -y --force-yes -t brewmaster debootstrap &> /dev/null; then
	
			echo -e "Package: debootstrap [OK]"
	
		else
	
			# echo and exit if package install fails
			echo -e "Package: debootstrap [FAILED] Exiting..."
			exit 1
	
		fi
	
	fi
	
	# Normal set of packages
	PKGs="pbuilder libselinux1 libselinux1:i386 lsb-release bc devscripts sudo \
	screen pv apt-file curl debian-keyring debian-archive-keyring ubuntu-archive-keyring \
	osc obs-build mock sbuild apt-cacher-ng quilt"

	for PKG in ${PKGs};
	do

		echo -e "Installing: "${PKG}""

		if sudo apt-get install -y --force-yes ${PKG} &> /dev/null; then

			echo -e "Package: ${PKG} [OK]"

		else

			# echo and exit if package install fails
			echo -e "Package: ${PKG} [FAILED] Exiting..."
			exit 1

		fi

	done
	
	echo -e "\n==> Updating cache for apt-file\n"
	sleep 2s
	
	# apt-file is a nice tool to search for packages/contents of packages in a CLI
	sudo apt-file update

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
		cd pacaur && makePKG
		sudo pacman -U ${PACOPTS} pacaur*.PKG.tar.xz

	else

		# just update pacaur targets (don't reinstall if up to date)
		pacaur -Sa ${AUROPTS} pacaur apt

	fi
	

	# Finally, get build tools needed out of the AUR
	# Pass -S to invoke pacman
	
	# AUR stage 1: required by 1 or more stage 2 pacakges
	pacaur -Sa ${AUROPTS} libxmltok
	
	# AUR stage 2 packages:
	pacaur -Sa ${AUROPTS} pbuilder-ubuntu debian-keyring debian-archive-keyring \
	ubuntu-archive-keyring ubuntu-keyring apt devscripts debsig-verify-git
	
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
		ROOT_DIR="${PWD}"
		AUR_INSTALL_DIR="${ROOT_DIR}/arch-aur-packages"
		MY_ARCH_PKGS="devscripts"
		
		for PKGs in ${MY_ARCH_PKGS};
		do

			cd "${AUR_INSTALL_DIR}/${PKG}" || exit 1
			makePKG -s
	
			# No 'else' logic here, we can't check for updates, no AUR of course.
			if ! sudo pacman -U ${PACOPTS} ${PKG}*.PKG.tar.gz; then
	
				echo "ERROR: Installation of ${PKG} failed. Exiting"
				exit 1
	
			fi

		done

	fi

	# Currently, the AUR package for dpkg does not include the vendor origins
	# Also, the configuration is missing for detection of system keyrings
	# These are included in the .devscripts conf file in this repo.
	sudo cp "${SCRIPTDIR}/etc/dpkg/origins/default" "/etc/dpkg/origins/"
	sudo cp "${SCRIPTDIR}/etc/dpkg/origins/debian" "/etc/dpkg/origins/"

	# Clean up manual AUR package installation DIRectory
	cd "${ROOT_DIR}"
	rm -rf "arch-aur-packages"

else

	echo -e "\nUnsupported OS/Distro! Exiting...\n"
	exit 1

fi

#################################################
# Block storage (e.g. on a VPS)
#################################################

cat<<-EOF

==> Setup block storage volume (VPS)?"
    WARNING: The volume WILL be formatted!

EOF

sleep 0.2s
read -erp "Choice [y/n]: " MOUNT_BLOCK_STORGE

if [[ "${MOUNT_BLOCK_STORGE}"  == "y" ]]; then

	# Set default
	VOLUME_NUM="1"

	while [[ ${VOLUME_NUM} -gt 0 ]];
	do

		# list volumes
		lsblk

		echo ""
		read -erp "Device location of volume (e.g. /dev/sdx) : " VOLUME_LOC
		read -erp "Mount label to apply: " VOLUME_NAME

		# unmount device if mounted
		sudo umount ${VOLUME_LOC}

		# Setup volume
		echo -e "\n==> Setting up volume ${VOLUME_NUM}, please wait."
		sleep 3s

		sudo parted ${VOLUME_LOC} mklabel gpt
		sudo parted -a opt ${VOLUME_LOC} mkpart primary ext4 0% 100%
		sudo mkfs.ext4 ${VOLUME_LOC}
		sudo mkdir -p /mnt/${VOLUME_NAME}
		echo "# Volume: ${VOLUME_LOC} setup" | sudo tee -a "/etc/fstab"
		echo "${VOLUME_LOC} /mnt/${VOLUME_NAME} ext4 defaults,nofail,discard 0 2" | sudo tee -a "/etc/fstab"

		# mount volumne and fail script if it did not complete
		if sudo mount -a; then
			echo -e "\nVolume: /mnt/${VOLUME_NAME} mounted successfully"
		else
			echo -e "\nVolume: /mnt/${VOLUME_NAME} mount failed! Exiting..."
			exit 1
		fi

		# See if this is the last volume
		echo -e "\nIs this the last volum you have to setup? [y/n]"
		sleep 0.2s
		read -erp "Choice: " LAST_VOLUME

		if [[ "${LAST_VOLUME}" == "n" ]]; then
			VOLUME_NUM=$((VOLUME_NUM + 1))

		else
			VOLUME_NUM=0
		fi

	done

fi

#################################################
# swap
#################################################

SYSTEM_SWAP_KB=$(cat /proc/meminfo | awk '/SwapTotal/{print $2}')
SYSTEM_SWAP_GB=$(echo "scale=2; ${SYSTEM_SWAP_KB}/1024/1024" | bc)

if [[ ${SYSTEM_SWAP_KB} == "0" ]]; then

	cat<<- EOF
	==> SWAP space warning!
	    It appears there is no swap space in use. This is a bad idea
	    for large builds on low-spec VPS instances. Setup?

	EOF
	
	read -erp "Choice [y/n]: " SETUP_SWAP
	
	if [[ "${SETUP_SWAP}" == "y" ]]; then

		read -erp "Size of swap spce in GB: " SWAP_SIZE_TEMP
		SWAP_SIZE=$((SWAP_SIZE_TEMP * 1000))
		sudo touch /var/swap.img
		sudo chmod 600 /var/swap.img
		sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=${SWAP_SIZE}
		sudo mkswap /var/swap.img
		sudo swapon /var/swap.img
		echo "# Manual setup swap space" | sudo tee -a /etc/fstab
		echo "/var/swap.img    none    swap    sw    0    0" | sudo tee -a /etc/fstab

	fi
	
fi

#################################################
# Create DIRectories
#################################################

echo -e "\n==> Adding needed Directories"
sleep 2s

STEAMOS_TOOLS_CONFIGS="${HOME}/.config/SteamOS-Tools"

DIRS="${STEAMOS_TOOLS_CONFIGS}"

for DIR in ${DIRS};
do
	if [[ ! -d "${DIR}" ]]; then

		mkdir -p "${DIR}"

	fi

done

#################################################
# Dot files
#################################################

echo -e "\n==> Adding and configuring dotfiles\n"
sleep 2s

#####################
# bashrc
#####################

# Reset setup? Check for headers
bashrc_test_start=$(grep "##### DEBIAN PACKAGING SETUP #####" "${HOME}/.bashrc")
bashrc_test_end=$(grep "##### END DEBIAN PACKAGING SETUP #####" "${HOME}/.bashrc")

if [[ "${bashrc_test_start}" != "" && "${bashrc_test_start}" != "" ]]; then

	echo -e "\nReset .bashrc? setup?"
	echo -e "This will remove GitHub, quilt, and host setups, etc."
	sleep 0.5s
	
	# info may already be setup, allow people to ignore it.
	
	read -erp "Choice [y/n]: " bashrc_choice
	
	if [[ "${bashrc_choice}" == "y" ]]; then
	
		# Reset setup for incoming vars
		sed -i '/##### DEBIAN PACKAGING SETUP #####/,/##### END DEBIAN PACKAGING SETUP #####/d' "${HOME}/.bashrc"
		
		cat "${SCRIPTDIR}/.bashrc" >> "${HOME}/.bashrc"
	
	fi
	
else

	# copy in template
	cat "${SCRIPTDIR}/.bashrc" >> "${HOME}/.bashrc"
	
fi

# Assess if TEMP vars exist, replace them
# Set bashrc information

if [[ $(grep "FULLNAME_TEMP" "${HOME}/.bashrc") != "" ]]; then

	read -erp "Maintainer full name: " FULLNAME_TEMP
	sed -i "s|FULLNAME_TEMP|${FULLNAME_TEMP}|" "${HOME}/.bashrc"

fi

if [[ $(grep "EMAIL_TEMP" "${HOME}/.bashrc") != "" ]]; then

	read -erp "GitHub Email: " EMAIL_TEMP
	sed -i "s|EMAIL_TEMP|${EMAIL_TEMP}|" "${HOME}/.bashrc"

fi

#####################
# Quilt
#####################

# Setup Quilt rc file for dpkg
cp "${SCRIPTDIR}/.quiltrc-dpkg" "${HOME}"
cp "${SCRIPTDIR}/.quiltrc" "${HOME}"

#####################
# devscripts
#####################

# devscripts
cp "${SCRIPTDIR}/.devscripts" "${HOME}"

#####################
# OBS
#####################

#cp "${SCRIPTDIR}/.devscripts" "${HOME}"

#####################
# Mock (for RPMs)
#####################

# Config files are in: /etc/mock/

# sudo usermod -a -G mock ${USER}
# cp "${SCRIPTDIR}/.site-defaults.cfg" "/etc/mock/"

#####################
# pbuilder
#####################

# pbuilder
cp "${SCRIPTDIR}/.pbuilderrc" "${HOME}/"
sudo cp "${SCRIPTDIR}/.pbuilderrc" "/root/"

#####################
# sbuild
#####################

# sbuild
cp "${SCRIPTDIR}/.sbuildrc" "${HOME}/"
sudo cp "${SCRIPTDIR}/.sbuildrc" "/root/"

#cp "${SCRIPTDIR}/.mk-sbuild.rc" "${HOME}/"
#sudo cp "${SCRIPTDIR}/.mk-sbuild.rc" "/root/"

#####################
# gdb
#####################

# very nice visual CLI tool for gdb
# See: https://github.com/cyrus-and/gdb-dashboard

wget -P ${HOME} git.io/.gdbinit -q -nc --show-progress

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
	read -erp "Choice [y/n]: " RESET_USERNAME

	if [[ "${RESET_USERNAME}"  == "y" ]]; then

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

# git uses x11-ssh-askpass if installed (GUI)

git config --global core.askpass ""

##################################################
# Host / Network
#################################################

# Set a remote host/user if desired now.
# All build scripts will default to a set value in the script if this is not set

echo -e "\n==> Setting host/network information"


echo -e "\nSetup/reset remote user/host for repository pool?"
echo -e "This is suggested if you are using a remote host"
read -erp "Choice [y/n]: " SET_HOST_USER

if [[ "${SET_HOST_USER}" == "y" ]]; then

	read -erp "Remote username: " REMOTE_USER_TEMP
	read -erp "Remote host: " REMOTE_HOST_TEMP
	read -erp "Remote port: " REMOTE_PORT_TEMP

	# Use wildcard to assume if it was set to something else before, clear it
	# when using double quotes here, you do not need to escape $ or =
	sed -i "s|REMOTE_USER.*|REMOTE_USER=\"${REMOTE_USER_TEMP}\"|" "${HOME}/.bashrc"
	sed -i "s|REMOTE_HOST.*|REMOTE_HOST=\"${REMOTE_HOST_TEMP}\"|" "${HOME}/.bashrc"
	sed -i "s|REMOTE_PORT.*|REMOTE_PORT=\"${REMOTE_PORT_TEMP}\"|" "${HOME}/.bashrc"

elif [[ "${SET_HOST_USER}" == "n" ]]; then

	# Set var to blank string so value inside build script is taken	
	# Use wildcard to assume if it was set to something else before, clear it
	sed -i "s|REMOTE_USER.*|REMOTE_USER=\"\"|" "${HOME}/.bashrc"
	sed -i "s|REMOTE_HOST.*|REMOTE_HOST=\"\"|" "${HOME}/.bashrc"
	sed -i "s|REMOTE_PORT.*|REMOTE_PORT=\"\"|" "${HOME}/.bashrc"
	
else

	# do nothing, assume n was answered, or wrong key entered
	:

fi

#####################
# Lintian
#####################

cp "${SCRIPTDIR}/.lintianrc" "${HOME}/"

#################################################
# Other configuration files
#################################################

echo -e "\n==> Adding other configuration files"
sleep 2s

cp "${SCRIPTDIR}/repo-exclude.txt" "${STEAMOS_TOOLS_CONFIGS}"
cp "${SCRIPTDIR}/repo-include.txt" "${STEAMOS_TOOLS_CONFIGS}"
cp "${SCRIPTDIR}/repo-filter.txt" "${STEAMOS_TOOLS_CONFIGS}"

#################################################
# Preferences
#################################################

# Editor
# Provided by sensible-utils, dependency of debianutils

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	select-editor

	# disable this line in bashrc if it exists so it does not interfere:
	sed -i "s|export EDITOR=.*|#export EDITOR=\"\"|g" "${HOME}/.bashrc"

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
	sed -i "s|EDITOR_TEMP|$EDITOR|" "${HOME}/.bashrc"
	
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
VALVE_KEYRING="valve-archive-keyring_0.5+bsos3_all"

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
	echo -e "\n==> Updating system for newly added keyrings\n"
	sleep 2s
	sudo apt-key update
	sudo apt-get update

elif [[ "${OS}" == "Arch" ]]; then

	# obtain keyring source for Valve archive keyring and convert it, not provided in AUR
	mkdir -p "${HOME}/setup-temp" && cd "${HOME}/setup-temp"
	wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/${VALVE_KEYRING}.deb" -q -nc --show-progress

	# Convert
	ar xv "${VALVE_KEYRING}.deb"
	tar -xvf data.tar.xz
	sudo cp "etc/apt/trusted.gpg.d/valve-archive-keyring.gpg" "/etc/apt/trusted.gpg.d/"
	sudo cp "usr/share/keyrings/valve-archive-keyring.gpg" "/usr/share/keyrings"
	
	# We also need to add the debian/ubuntu keyrings to the gpg trusted list
	# sudo cp /usr/share/keyrings/debian* "/etc/apt/trusted.gpg.d/"
	# sudo cp /usr/share/keyrings/ubuntu* "/etc/apt/trusted.gpg.d/"

	# cleanup
	cd ..
	rm -rf "${HOME}/setup-temp"

fi

# Setup Debian specific (such as the Valve keyring)
# This package is obviously in SteamOS already

if [[ "${OS}" == "Debian" ]]; then

	# Obtain valve keyring
	wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/${VALVE_KEYRING}.deb" -q --show-progress -nc 
	sudo dpkg -i "valve-archive-keyring_0.5+bsos3_all.deb"

fi

##########################
# Pbuilder folders
##########################

echo -e "\nAdding pbuilder folders"
sleep 1s

# See if user wants to link pbuilder folders to block storage
# This is a good idea for large builds on cost-effective VPS instances
# Use KB as a standard (though obviously slim chance dist is <= 1GB)
ROOT_PART_SIZE_KB=$(df -k | awk '$6 == "/" {print $4}')
HOME_PART_SIZE_KB=$(df -k | awk '$6 == "/home" {print $4}')

# Ensure our availabe hard drive size is more than 20971520 KB (20 GB binary)
if [[ ${ROOT_PART_SIZE_KB} -lt 20971520 && ${HOME_PART_SIZE_KB} -lt 20971520 ]]; then

	cat<<- EOF
	
	==> (optional) Link pbuilder folders
	
	It appears you have < 20G space on the root partition
	or $HOME drive. Would you like to symlink your pbuilder 
	folders to another location? [y/n]
	
	EOF
	
	sleep 0.2s
	read -erp "Choice: " LINK_PBUILDER
	
	if [[ "${LINK_PBUILDER}" == "y" ]]; then
		
		sleep 0.2s
		echo -e "\nLink pbuilder folders to what path?"

		read -erp "Path: " PBUILDER_LINK_PATH
		
	fi

fi

# root on SteamOS is small, divert cache DIR if applicable
# Also adjust for other locations, due to limited space on root
# LOCAL_REPO is defined in pbuilderc
OS=$(lsb_release -si)

if [[ "${OS}" == "SteamOS" ]]; then

	PBUILDER_ROOT="${HOME}/pbuilder"
	SYSTEM_PATH="false"

else

	PBUILDER_ROOT="/var/cache/pbuilder"
	SYSTEM_PATH="true"

fi

# create folders required
sudo rm -rf "${PBUILDER_ROOT}/hooks"
sudo mkdir -p "${HOME}/pbuilder/${DIST}/aptcache/"
sudo cp -r "${SCRIPTDIR}/hooks" "${PBUILDER_ROOT}"
sudo mkdir -p "${PBUILDER_ROOT}/local_repo"

# Link folders if var is set	
if [[ "${PBUILDER_LINK_PATH}" != "" ]]; then

	# link paths
	sudo ln -s "${PBUILDER_ROOT}" "${PBUILDER_LINK_PATH}"
fi

# Own folders as user if not a system path
if [[ "${SYSTEM_PATH}" == "false" ]]; then

	sudo chown -R $USER:$USER ${PBUILDER_ROOT}

fi

#################################################
# sbuild setup
#################################################

# See: https://wiki.ubuntu.com/SimpleSbuild
# See also: https://wiki.debian.org/sbuild

# Upating:
# List: schroot -l | grep sbuild
# Update: sudo sbuild-update -udcar [CHROOT_NAME]-[ARCH]

echo -e "\n==> Configuring sbuild\n"
sleep 2s

# Directories

sudo mkdir -p "/srv/chroot/"

echo -e "Setup root user sbuild SSH key? (takes some time)"
sleep 0.3s
read -erp "Choice [y/n]: " SBUILD_SSH

if [[ "${SBUILD_SSH}"  == "y" ]]; then

	echo -e "Generating Keygen\n"
	sudo mkdir /root/.gnupg
	sudo sbuild-update --keygen

fi

# Users

#sudo adduser "${USER}" sbuild
sudo sbuild-adduser "${USER}" &> /dev/null

echo -e "Note: You will need to logout and back in to use sbuild"
sleep 5s

# Set the directory to the existing pbuilder hooks

#if [[ "${OS}" == "SteamOS" ]]; then

#	sed -i "s|.*pre-build.*|"pre-build-commands" => ['bash $HOME/pbuilder/hooks/D20steamos-tools-hook.sh']|" "${HOME}/.sbuildrc"

#else

#	sed -i "s|.*pre-build.*|"pre-build-commands" => ['bash /var/cache/pbuilder/D20steamos-tools-hook.sh']|" "${HOME}/.sbuildrc"

#fi

#################################################
# OpenSUSE - Open Build System setup
#################################################

# TODO ?


#################################################
# Extra setup
#################################################

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

# ubuntu
# None for now

echo -e "\nFinishing up"
sleep 0.5s

# output help
cat <<-EOF

################################################################
Summary
################################################################

Creating a pbuilder chroot setup:
sudo -E DIST=[DIST] ARCH=[ARCH] pbuilder create

Creating a sbuild basic setup:
sudo sbuild-createchroot --include=eatmydata,ccache,gnupg [DIST] \
/srv/chroot/[DIST]-[ARCH] [URL_TO_DIST_POOL]

Ex. dist pool: http://httpredir.debian.org/debian

EOF

#################################################
# Cleanup
#################################################

# source bashrc for this session
. ${HOME}/.bashrc
