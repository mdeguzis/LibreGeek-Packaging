#!/bin/bash
# Builds a clean chroot for an Arch system

mkdir -p $HOME/chroot
export CHROOT=$HOME/chroot

if [[ ! -d $CHROOT/root ]]; then
	if ! mkarchroot $CHROOT/root base-devel; then
		echo "Failed to create chroot"
		exit 1
	fi
else
	echo "NOTICE: $CHROOT already exists, skipping"
fi

# Update
echo "NOTICE: Updating system..."
sleep 2s
arch-nspawn $CHROOT/root pacman -Syu


