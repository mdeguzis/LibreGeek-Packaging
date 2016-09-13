#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/LibreGeek-Packaging
# Scipt name:	create-arch-chroot.sh
# Script Ver:	0.1.1
# Description:	Creates an Arch Linxu chroot on Linus systems
# See:		
#
# Usage:	./create-arch-chroot.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

# Test OS first, so we can allow configuration on multiple distros
OS=$(lsb_release -si)
MULTIARCH=$(dpkg --print-foreign-architectures | grep i386)

if [[ "${OS}" == "SteamOS" || "${OS}" == "Debian" ]]; then

	# Supported
	:
	
else

	echo -e "Distribution not yet supported"
	
fi
