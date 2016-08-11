#!/bin/bash

# Get utils
sudo apt-get install -y yum

# Vars
CHROOT_DEVEL=/chroot/devel/
CHROOT_BASE="${CHROOT_DEVEL}/var/lib/"

# 1 - Create the chroot directory
sudo mkdir -p ${CHROOT_BASE}/rpm

# 2 - Initiate rpm db on chroot
sudo rpm --root ${CHOOR_DEVEL} --initdb

# 3 - download Fedora Release package.
# If you do not want Fedora, download the correct *-release package and use it 
# on step 4. There are examples on the references.
yumdownloader --destdir=/tmp fedora-release

# 4 - Install downloaded Fedora release inside chroot
sudo rpm --root ${CHOOR_DEVEL} -ivh /tmp/fedora-release*rpm

# If you want more than just bash, see 5a - OPTIONAL
# 5 - Install bash and its dependencies on the jail.
# For different versions of Fedora or to install other RPM based distros, it will be
# necessary to configure the correct yum repositories outside the jail, so yum
# can download the correct packages.
sudo yum --installroot=${CHOOR_DEVEL} install bash

#5a - OPTIONAL: Do a minimum system install
# If you want all packages from the minimum install option
# `yum grouplist` show all available groups
sudo yum --installroot=${CHOOR_DEVEL} groupinstall "minimal install"

#Post-Notes:

#- To enter the jail:
#	$ sudo chroot /chroot/devel
#- If you want to install yum inside the jail:
#	$ sudo yum --installroot=/chroot/devel install yum

