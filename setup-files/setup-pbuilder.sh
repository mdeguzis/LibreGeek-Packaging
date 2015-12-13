
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

#####################################
# Dependencies
#####################################

echo -e "\n==> Installing depedencies for packaging and testing\n"
sleep 2s

sudo apt-get install -y build-essential fakeroot devscripts cowbuilder pbuilder debootstrap

#####################################
# PBUILDER setup
#####################################

# set the /var/cache/pbuilder/result directory writable by your user account.
sudo chmod u+w /var/cache/pbuilder/result

# create a directory, e.g. /var/cache/pbuilder/hooks, writable by the user, to place hook scripts in.
sudo mkdir -p /var/cache/pbuilder/hooks
sudo chown $USER:$USER /var/cache/pbuilder/hooks

# setup cache directory
sudo mkdir /var/cache/pbuilder/repo
sudo chmod 777 /var/cache/pbuilder/repo

# copy files based of pwd
touch "$HOME/.pbuilderrc"
sudo touch "/root/.pbuilderrc"
cp .pbuilderrc "$HOME/.pbuilderrc"
sudo cp .pbuilderrc "/root/.pbuilderrc"

# create hooks dir
sudo mkdir -p /usr/lib/pbuilder/hooks

# (Optional) Create /usr/lib/pbuilder/hooks/C10shell with the following content
sudo cp C10shell /usr/lib/pbuilder/hooks/C10shell
sudo chmod +x /usr/lib/pbuilder/hooks/C10shell

# Create /usr/lib/pbuilder/hooks/D05deps
sudo cp D05deps /usr/lib/pbuilder/hooks/D05deps
	
# create directory for dependencies
mkdir -p "/home/$USER/${dist_choice}-packaging/deps"

# Now we need to initialize the “Packages” file for the empty repo so we 
# can work the first time:
dpkg-scanpackages /var/cache/pbuilder/repo > /var/cache/pbuilder/repo/Packages

# (OPTIONAL)  If you have lots of RAM (more than 4 GB) putting the pbuilder “build” 
# chroot on tmpfs will speed it up immensely.  so add the following to /etc/fstab 
# (it should be all on one line starting with “tmpfs” and ending with the second zero.


# remove old /etc/fstab entries
sudo sed -ie "\:#pbuilder tmpfs:,+1d" "/etc/fstab"

fstab_check=$(cat /etc/fstab | grep pbuilder)
if [[ "$fstab_check" == "" ]]; then

	sudo su -c "echo '#pbuilder tmpfs' >> /etc/fstab"
	sudo su -c "echo 'tmpfs   /var/cache/pbuilder/build       tmpfs   defaults,size=2400M 0 0' >> /etc/fstab"
	
fi

# mount fstab it with 
sudo mount /var/cache/pbuilder/build

# output help
cat <<-EOF

Creating:
'sudo DIST=${dist} ARCH=${arch} pbuilder create'

Updating
'sudo DIST=${dist} ARCH=${arch} pbuilder update'

EOF
