#!/bin/bash
# Builds a clean chroot for an Arch system

# Mirros messed up preventing -Syu from running?
# pacman-mirrors --geoip && cp /etc/pacman.d/mirrorlist .

mkdir -p $HOME/chroot
export CHROOT=$HOME/chroot

# Set command based on Arch or Manjoro
if [[ $(lsb_release -i | grep -i Manjaro) != "" ]]; then
	nspawn_command="manjaro-nspawn"
	chroot_command="mkmanjaroroot"
elif [[ $(lsb_release -i | grep -i Manjaro) != "" ]]; then
	nspawn_command="arch-nspawn"
	chroot_command="mkarchchroot"	

else
	"ERROR: Cannot determine command for nspawn"
	exit 1
fi

if [[ ! -d $CHROOT/root ]]; then
	if ! ${chroot_command} $CHROOT/root base-devel; then
		echo "Failed to create chroot"
		exit 1
	fi
else
	echo "NOTICE: $CHROOT already exists, skipping"
fi

# Update
echo "NOTICE: Updating system..."
sleep 2s
${nspawn_command} $CHROOT/root pacman -Syu


