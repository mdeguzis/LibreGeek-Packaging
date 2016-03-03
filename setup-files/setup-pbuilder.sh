
#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:		        https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:   	build-pbuilder-env.sh
# Script Ver:		0.3.9
# Description:		Create buld environment for testing and building packages
# Usage:		./setup-pbuilder.sh
#
# Notes:          	For targets, see .pbuilderrc in this directory
# -------------------------------------------------------------------------------

#####################################
# Information
#####################################

# http://blogs.libreems.org/setup-pbuilder-make-clean-debian-packages/
# https://wiki.debian.org/PbuilderTricks

cat<<- EOF
#########################################
Pbuilder Setup for SteamOS Packaging
#########################################

EOF
sleep 2s

echo -e "==> Installing keyrings\n"
sleep 2s

# Set vars
valve_keyring="valve-archive-keyring_0.5+bsos3_all"

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# Obtain valve keyring
	wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/${valve_keyring}.deb" -q --show-progress -nc 
	sudo dpkg -i "valve-archive-keyring_0.5+bsos3_all.deb"
	
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

#####################################
# PBUILDER setup
#####################################

# set the /var/cache/pbuilder/result directory writable by your user account.
sudo chmod u+w /var/cache/pbuilder/result

##########################
# Hooks
##########################

echo -e "\n==> Adding pbuilder hooks"
sleep 0.5s

if [[ ! -d "/var/cache/pbuilder/hooks" ]]; then

	sudo mkdir /var/cache/pbuilder/hooks
	sudo chown -R $USER /var/cache/pbuilder/hooks
	
fi

##########################
# core configs
##########################

# IMPORTANT!
# For information, see: http://manpages.ubuntu.com/manpages/precise/man5/pbuilderrc.5.html

# copy files based of pwd
echo -e "\n==> Adding pbuilder config files"
sleep 0.5s

cp "$scriptdir/.pbuilderrc" "$HOME/"
sudo cp "$scriptdir/.pbuilderrc" "/root/"

# create directory for dependencies
mkdir -p "/home/$USER/${dist_choice}-packaging/deps"

# (OPTIONAL)  If you have lots of RAM (more than 4 GB) putting the pbuilder “build” 
# chroot on tmpfs will speed it up immensely.  so add the following to /etc/fstab 
# (it should be all on one line starting with “tmpfs” and ending with the second zero.

echo -e "\n==> Adding symlinks for /usr/share/debootstrap/scripts"
sleep 2s

# brewmaster
sudo ln -s "/usr/share/debootstrap/scripts/jessie" "/usr/share/debootstrap/scripts/brewmaster" 2> /dev/null
sudo ln -s "/usr/share/debootstrap/scripts/jessie" "/usr/share/debootstrap/scripts/brewmaster_beta" 2> /dev/null

# alchemist
sudo ln -s "/usr/share/debootstrap/scripts/wheezy" "/usr/share/debootstrap/scripts/alchemist" 2> /dev/null
sudo ln -s "/usr/share/debootstrap/scripts/wheezy" "/usr/share/debootstrap/scripts/alchemist_beta" 2> /dev/null

##########################
# core configs
##########################

#echo -e "\n==> Processing fstab"
#sleep 0.5s

# remove old /etc/fstab entries
sudo sed -ie "\:#pbuilder tmpfs:,+1d" "/etc/fstab"

#fstab_check=$(cat /etc/fstab | grep pbuilder)
#if [[ "$fstab_check" == "" ]]; then

#	sudo su -c "echo '#pbuilder tmpfs' >> /etc/fstab"
#	sudo su -c "echo 'tmpfs   /var/cache/pbuilder/build       tmpfs   defaults,size=2400M 0 0' >> /etc/fstab"
	
#fi

# mount fstab it with 
#sudo mount /var/cache/pbuilder/build

echo -e "\n==> Finishing up"
sleep 0.5s

# output help
cat <<-EOF

################################################################
Summary
################################################################
Creating:
pbuilder-wrapper create [DIST] [ARCH]

Updating
pbuilder-wrapper update [DIST] [ARCH]

EOF
