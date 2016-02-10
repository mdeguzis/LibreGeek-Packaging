#!/bin/bash
# -------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	configure-packaging-env.sh
# Script Ver:	1.3.1
# Description:	Installs basic packaging tools suggested by the Debian
#               maintainers guide and configures various packaging options
#
# See:		https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs
# Usage:	./configure-packaging-env.sh
# -------------------------------------------------------------------------------

clear
echo -e "Installing basic packages"
sleep 2s

##################################################
# Base packages
#################################################

sudo apt-get install -y --force-yes build-essential autoconf automake and \
autotools-dev debhelper dh-make devscripts fakeroot git lintian patch patchutils \
pbuilder perl python quilt xutils-de dh-make devscripts

##################################################
# dh
#################################################

echo -e "Configuring dh_make\n"
sleep 2s

# Ask user for repos / vars
read -erp "Email: " email
read -erp "First Name: " first_name
read -erp "Last Name: " first_name

# set tmp var for last run, if exists
repo_src_tmp="$repo_src"

####################################################################
# Debuild
####################################################################

# debuild default options
cat<<- EOF> $HOME/.devscripts
##################################################
# Notes
##################################################
# -us   Do not sign the source package.
# -uc   Do not sign the .changes file.
# -i[regex]
# -I[pattern]

# Re: debuild -i, to avoid editor backup files and version control metadata...
# Source packages using the latest “3.0 (quilt)” and “3.0 (native)” 
# formats do not have this problem anymore, the -i -I options 
# are enabled by default for them.
# For the old (“1.0”) source format, it’s still needed.

# See: 'man debuild'

##################################################
# Set defaults
##################################################
DEBUILD_DPKG_BUILDPACKAGE_OPTS="-us -uc"
DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
EOF

####################################################################
# General packaging defaults
####################################################################

cat << EOF > $HOME/.bashrc
##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="${email}"
DEBFULLNAME="$first_name $last_name"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt
EOF

####################################################################
# Quilt options
####################################################################

# Setup Quilt rc file

cat <<-EOF > $HOME/.quiltrc
for where in ./ ../ ../../ ../../../ ../../../../ ../../../../../; do
if [ -e ${where}debian/rules -a -d ${where}debian/patches ]; then
        export QUILT_PATCHES=debian/patches
        break
fi
done

QUILT_PUSH_ARGS="--color=auto"
QUILT_DIFF_ARGS="--no-timestamps --no-index -p ab --color=auto"
QUILT_REFRESH_ARGS="--no-timestamps --no-index -p ab"
QUILT_DIFF_OPTS='-p'
EOF

# Setup Quilt rc file for dpkg

cat <<-EOF > $HOME/.quiltrc-dpkg
d=. ; while [ ! -d $d/debian -a `readlink -e $d` != / ]; do d=$d/..; done
if [ -d $d/debian ] && [ -z $QUILT_PATCHES ]; then
    # if in Debian packaging tree with unset $QUILT_PATCHES
    QUILT_PATCHES="debian/patches"
    QUILT_PATCH_OPTS="--reject-format=unified"
    QUILT_DIFF_ARGS="-p ab --no-timestamps --no-index --color=auto"
    QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index"
    QUILT_COLORS="diff_hdr=1;32:diff_add=1;34:diff_rem=1;31:diff_hunk=1;33:diff_ctx=35:diff_cctx=33"
    if ! [ -d $d/debian/patches ]; then mkdir $d/debian/patches; fi
fi
EOF

####################################################################
# Pbuilder
####################################################################

# setup pbuilder
./setup-pbuilder.sh

####################################################################
# Cleanup
####################################################################

# source bashrc
. $HOME/.bashrc

