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

clear
echo -e "Installing basic packages"
sleep 2s

sudo apt-get install -y --force-yes build-essential autoconf automake and \
autotools-dev debhelper dh-make devscripts fakeroot git lintian patch patchutils \
pbuilder perl python quilt xutils-de dh-make

echo -e "Configuring dh_make\n"
sleep 2s

# Ask user for repos / vars
read -erp "Email: " email
read -erp "First Name: " first_name
read -erp "Last Name: " first_name

# set tmp var for last run, if exists
repo_src_tmp="$repo_src"

cat >>~/.bashrc <<EOF
##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="${email}"
DEBFULLNAME="$first_name $last_name"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt
EOF

# Setup Quilt rc file

if [[ ! -f "~/.quiltrc-dpkg" ]]; then

  # create file
  touch ~/.quiltrc-dpkg
  
fi

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

# source bashrc
. ~/.bashrc

