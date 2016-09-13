#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/LibreGeek-Packaging
# Scipt name:	create-arch-chroot.sh
# Script Ver:	0.1.1
# Description:	Creates an Arch Linxu chroot on Linus systems
# See:		https://wiki.archlinux.org/index.php/Install_from_existing_Linux
#		Section: #From_a_host_running_another_Linux_distribution
#
# Usage:	./create-arch-chroot.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)
MULTIARCH=$(dpkg --print-foreign-architectures | grep i386)

echo -e "\n==> Acquiring distro-specific dependencies\n"
sleep 2s

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# get basic depdencies
	sudo apt-get -install -y --force-yes bash coreutils wget sed gawk  \
	tar gzip chroot xz
	
else

	echo -e "This distro is not supported quite yet: "
	echo -e "${OS}"
	sleep 5s
	exit 1

fi

echo -e "\n==> Acquiring arch-boostrap\n"
sleep 2s

# For now, use a cool helper script linked in the AUR article to make this 
# easy

rm -f arch-bootstrap.sh
rm -f get-pacman-dependencies.sh

wget "https://raw.githubusercontent.com/tokland/arch-bootstrap/master/arch-bootstrap.sh" \
-q -nc --show-progress

wget "https://raw.githubusercontent.com/tokland/arch-bootstrap/master/get-pacman-dependencies.sh" \
-q -nc --show-progress

# Mark exec (if not already)
chmod +x get-pacman-dependencies.sh
chmod +x arch-bootstrap.sh

echo -e "\n==> Boostrapping Arch Linux install\n"
sleep 2s

read -erp "Install location: " INSTALL_LOCATION

if [[ -d "${INSTALL_LOCATION}" ]]; then

	echo -e "\nDestination path taken! Reset?"
	read -erp "Choice (y/n): " RESET

	if [[ "${RESET}" == "y" ]]; then

		rm -rf "${INSTALL_LOCATION}"
	
	else

else

	# ensure directory is present
	mkdir -p "${INSTALL_LOCATION}"

fi

if sudo ./arch-bootstrap.sh -a x86_64 -r "ftp://ftp.archlinux.org" "${INSTALL_LOCATION}"; then

	echo -e "\nInstallation Successful!"

else

	echo -e "\nInstallation failed!"
	sleep 5s
	exit 1

fi

echo -e "\n==> Binding mounts for Arch Linus install\n"
sleep 2s

sudo mount --bind /proc "${INSTALL_LOCATION}/proc"
sudo mount --bind /sys "${INSTALL_LOCATION}/sys"
sudo mount --bind /dev "${INSTALL_LOCATION}/dev"
sudo mount --bind /dev/pts "${INSTALL_LOCATION}/dev/pts"

# cleanup

echo -e "\n==INFO==\nTo enter the chroot:"
echo -e "chroot ${INSTALL_LOCATION}"

