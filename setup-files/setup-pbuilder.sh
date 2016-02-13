
#!/bin/bash
# -------------------------------------------------------------------------------
# Author:		Michael DeGuzis
# Git:		        https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:   	build-pbuilder-env.sh
# Script Ver:		0.3.9
# Description:		Create buld environment for testing and building packages
# Usage:		./build-pbuilder-env.sh [distribution] [arch]
#
# Notes:          	For targets, see .pbuilderrc in this directory
# -------------------------------------------------------------------------------

#####################################
# Information
#####################################

# http://blogs.libreems.org/setup-pbuilder-make-clean-debian-packages/
# https://wiki.debian.org/PbuilderTricks

#####################################
# Dependencies
#####################################

cat<<- EOF
#########################################
Pbuilder Setup for SteamOS Packaging
#########################################

EOF
sleep 2s

echo -e "\n==> Installing Valve keyrings\n"
sleep 2s

# Obtain valve keyring
wget "http://repo.steamstatic.com/steamos/pool/main/v/valve-archive-keyring/valve-archive-keyring_0.5+bsos3_all.deb"
sudo dpkg -i "valve-archive-keyring_0.5+bsos3_all.deb"

# update for keyrings

echo -e "\n==> Updating system for newly added keyrings\n"
sleep 2s
sudo apt-key update
sudo apt-get update

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

# create hooks dir
sudo mkdir -p /usr/lib/pbuilder/hooks

# (Optional) Create /usr/lib/pbuilder/hooks/C10shell with the following content
sudo cp C10shell /usr/lib/pbuilder/hooks/C10shell
sudo chmod +x /usr/lib/pbuilder/hooks/C10shell

# Create /usr/lib/pbuilder/hooks/D05deps
sudo cp D05deps /usr/lib/pbuilder/hooks/D05deps

##########################
# Cache directory
##########################
echo -e "\n==> Adding cache setup"
sleep 0.5s

# create a directory, e.g. /var/cache/pbuilder/hooks, writable by the user, to place hook scripts in.
sudo mkdir -p /var/cache/pbuilder/hooks
sudo chown $USER:$USER /var/cache/pbuilder/hooks

sudo rm -rf /var/cache/pbuilder/repo
sudo mkdir /var/cache/pbuilder/repo
sudo chmod 777 /var/cache/pbuilder/repo

##########################
# core configs
##########################

# copy files based of pwd
echo -e "\n==> Adding pbuilder config files"
sleep 0.5s

cp "$scriptdir/.pbuilderrc" "$HOME/"
sudo cp "$scriptdir/.pbuilderrc" "/root/"

# create directory for dependencies
mkdir -p "/home/$USER/${dist_choice}-packaging/deps"

# Now we need to initialize the “Packages” file for the empty repo so we 
# can work the first time:
dpkg-scanpackages /var/cache/pbuilder/repo > /var/cache/pbuilder/repo/Packages

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
'sudo DIST=${dist} ARCH=${arch} pbuilder create [--keyring=]'

Updating
'sudo DIST=${dist} ARCH=${arch} pbuilder update'

EOF
