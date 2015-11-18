#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	install-pkg-tools.sh
# Script Ver:	1.0.0
# Description:	Simply installs basic packaging tools suggested by the Debian
#               maintainers guide.
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	install-pkg-tools.sh
# -------------------------------------------------------------------------------

sudo apt-get install -y --force-yes build-essential autoconf automake and \
autotools-dev debhelper dh-make devscripts fakeroot git lintian patch patchutils \
pbuilder perl python quilt xutils-de
