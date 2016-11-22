#!/bin/bash

# Creates base fedora image for Docker
# Author: Michael DeGuzis
# TODO: fix up code for arugment processing
# Sourced from: https://github.com/ProfessorKaos64/docker/blob/fedora-32/create-fedora-docker.sh

# Set main var defaults
RELEASE="24"
REVISION="3"
ARCH="x86_64"
CHROOT_NAME="fedora-${RELEASE}-${ARCH}"
CHROOT_BASE="${HOME}/${CHROOT_NAME}"
BASE_URL="https://kojipkgs.fedoraproject.org/packages/fedora-repos"
REPO_RPM="${BASE_URL}/${RELEASE}/${REVISION}/noarch/fedora-repos-${RELEASE}-${REVISION}.noarch.rpm"
BUILD_SCRIPT="https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-yum.sh"
BASE_GROUPS="Core"
BASE_PKGS="base base-devel"


usage()
{

	cat<<- EOF

	$(basename $0) [OPTIONS] <name>
	OPTIONS:
	-a "<ARCH>"    		Arhitecture to use
				The default is x86_64.
	-g "<GROUPS>"    	Added groups to install
				The default is base, base-devel
	-n "<name>"		Desired name. Use your repo name if uploading later
				The default is fedora-${ARCH}.
	-p "<PACKAGES>"    	Added packages to install
				The default is base base-devel.
	-r "<fedora_rel_num>"	Fedora release number to use
				The default is 24.

	EOF

}

check_distro()
{

	# Check first if we are using Fedora or Debian etc.
	# Distros, such as Debian, only have yum at the moment

	if which lsb_release &> /dev/null; then

		OS=$(lsb_release -si)

	else

		OS=$(cat /etc/os-release | grep -w "NAME" | cut -d'=' -f 2)

	fi

	if [[ "${OS}" == "Debian" || "${OS}" == "SteamOS" ]]; then

		PKG_HANDLER="yum"
		PKG_CONF="/etc/yum/yum.conf"

		# Install yum
		sudo apt-get install -y yum

	elif [[ "${OS}" == "Fedora" ]]; then

		PKG_HANDLER="dnf"
		PKG_CONF="/etc/dnf/dnf.conf"

	else

		# Assume only yum available
		PKG_HANDLER="yum"
		PKG_CONF="/etc/yum/yum.conf"

	fi

}

build_image()
{
	if [[ -d "${CHROOT_BASE}" ]]; then

		rm -rf "${CHROOT_BASE}"
		mkdir -p "${CHROOT_BASE}"

	else

		mkdir -p "${CHROOT_BASE}"


	fi

	# Set folder locations
	RPM_PKG_DB="${CHROOT_BASE}/var/lib/rpm"
	PKG_ROOT="${CHROOT_BASE}/${PKG_HANDLER}"
	CHROOT_PKG_CONF="${PKG_ROOT}/${PKG_HANDLER}.conf"

	# Create required directories
	mkdir -p "${RPM_PKG_DB}"
	mkdir -p "${PKG_ROOT}"

	# Enter tmp dir
	cd "${CHROOT_BASE}" || exit 1

	# Download required files

	wget "${BUILD_SCRIPT}" -q -nc --show-progress

	# Getting revision 3 fails, try revision 2 or 1
	if ! wget "${REPO_RPM}" -q -nc --show-progress; then

		echo -e "\nERROR: Cannot find this file, trying revision 2\n"
		REPO_RPM="${BASE_URL}/${RELEASE}/2/noarch/fedora-repos-${RELEASE}-2.noarch.rpm"

			if ! wget "${REPO_RPM}" -q -nc --show-progress; then

				echo -e "\nERROR: Cannot find this file, trying revision 1\n"
				REPO_RPM="${BASE_URL}/${RELEASE}/1/noarch/fedora-repos-${RELEASE}-1.noarch.rpm"
				wget "${REPO_RPM}" -q -nc --show-progress

			fi

	fi

	# Ensure rpm pkg is available after nabbing the package configs, bail out if not
	if [[ ! -f $(basename ${REPO_RPM}) ]]; then

		echo -e "\nERROR: could not find specified RPM package! Aborting."
		sleep 5s
		exit 1

	fi

	# Mark utility exec
	chmod +x mkimage-yum.sh

	# Extract and modify base source repos RPM
	# See: http://www.cyberciti.biz/tips/how-to-extract-an-rpm-package-without-installing-it.html

	rpm2cpio $(basename ${REPO_RPM}) | cpio -idmv

	# Proceed as long as etc exists

	if [[ -d "${CHROOT_BASE}/etc" && -f "${PKG_CONF}" ]]; then

		# copy PKG_CONF from system
		# dnf still pulls from /etc/yum/yum.repos.d/ for extra configuration

		cp "${PKG_CONF}" "${CHROOT_PKG_CONF}"
		sed -i "s/\$releasever/${RELEASE}/g" ${CHROOT_BASE}/etc/yum.repos.d/*
		sed -i "s/\$basearcg/${ARCH}/g" ${CHROOT_BASE}/etc/yum.repos.d/*

		# Enable base repos
		sed -i "s/\enabled\=0/enabled\=1}/g" "${CHROOT_BASE}/etc/yum.repos.d/fedora.repo"
		sed -i "s/\enabled\=0/enabled\=1}/g" "${CHROOT_BASE}/etc/yum.repos.d/fedora-updates.repo"

		# Disable GPG check for image build
		sed -i "s/\gpgcheck\=1/gpgcheck\=0}/g" "${CHROOT_BASE}/etc/yum.repos.d/fedora.repo"
		sed -i "s/\gpgcheck\=2/gpgcheck\=0}/g" "${CHROOT_BASE}/etc/yum.repos.d/fedora-updates.repo"

		# Add the contents of the repo files to etc
		# mkimage-yum.sh only uses the base .conf file to build the repo information
		find "${CHROOT_BASE}/etc" -type f -name '*.repo' -exec cat '{}' >> "${CHROOT_PKG_CONF}" \;


	else

		echo -e "\nERROR: Cannot find etc directory or ${PKG_CONF}!"
		exit 1
	fi

	# Initialize RPM DB
	rpm --root "${CHROOT_BASE}" --initdb

	# Install base packages
	if ! yum --installroot="${CHROOT_BASE}" groupinstall -y base; then

		echo -e "\nERROR: Failed to create image! Exiting"

		# cleanup
		if [[ -d "${CHROOT_BASE}" ]]; then

#			rm -rf "${CHROOT_BASE}"
:
		fi

	else

		# cleanup only
		if [[ -d "${CHROOT_BASE}" ]]; then

			rm -rf "${CHROOT_BASE}"

		fi		

	fi

}

# Set ARCH, REVISION and release and release defaults
while getopts ":a:g:n:p:r" opt; do
	case $opt in

		r)
	    	RELEASE=$OPTARG
		;;

		a)
	    	ARCH=$OPTARG
	    	;;

		n)
	    	NAME=$OPTARG
	    	;;

		g)
	    	BASE_GROUPS="$OPTARG"
		;;

		p)
	    	BASE_PKGS="$OPTARG"
		;;

		\?)
		echo "Invalid option: -$OPTARG"
		usage
		;;

	esac
done
shift $((OPTIND - 1))

#############################
# Start script
#############################
check_distro
build_image
