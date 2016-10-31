#!/bin/bash 

# Creates base fedora image for Docker
# Author: Michael DeGuzis


# Set main var defaults

RELEASE="24"
REVISION="3"
ARCH="i386"

usage() 
{

	cat<<- EOF
	$(basename $0) [OPTIONS] <name>
	OPTIONS:
	-r "<fedora_release>"	Fedora release to use
	-a "<ARCH>"    		Arhitecture to use
	-p "<PACKAGEES>"    	Added packages to install (not enabled right now)

	EOF
	exit 1

}

# Set ARCH, REVISION and release and release defaults
while getopts ":y:p:g:h" opt; do
	case $opt in

		r)
	    	RELEASE=$OPTARG
		;;

		a)
	    	ARCH=$OPTARG
	    	;;

		p)
	    	PACKAGES="$OPTARG"
		;;

		\?)
		echo "Invalid option: -$OPTARG"
		usage
		;;

	esac
done
shift $((OPTIND - 1))

# Set vars
RELEASE="$RELEASE_OPT"
REVISION="$REVSION_OPT"
ARCH="$ARCH_OPT"
IMAGE_NAME="Fedora-${RELEASE}-${ARCH}"
BASE_URL="https://kojipkgs.fedoraproject.org/packages/fedora-repos"
REPO_RPM="${BASE_URL}/${RELEASE}/${REVISION}/noarch/fedora-repos-${RELEASE}-${REVISION}.noarch.rpm"
BUILD_SCRIPT="https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-yum.sh"
BASE_PKGS="base base-devel"

build_image()
{
	if [[ -f "${TMP_DIR}" ]]; then

		rm -rf "${TMP_DIR}"
		mkdir -p "${TMP_DIR}"

	else

		mkdir -p "${TMP_DIR}"


	fi

	# Set conf location
	DNF_CONF="${TMP_DIR}/etc/dnf"

	# Enter tmp dir

	cd "${TMP_DIR}"

	# Download required files

	wget "${BUILD_SCRIPT}" -q -n --show-progress

	# if this fails, use revision 1, whichi shoudl always exist

	if ! wget "${REPO_RPM}" -q -nc --show-progress; then

		echo -e "\nERROR: Cannot find this file, using revision 1\n"
		REPO_RPM="${BASE_URL}/${RELEASE}/1/noarch/fedora-repos-${RELEASE}-1.noarch.rpm"
		wget "${REPO_RPM}" -q -nc --show-progress

	fi

	chmod +x mkimage-yum.sh

	# Extract and modify base source repos RPM
	# See: http://www.cyberciti.biz/tips/how-to-extract-an-rpm-package-without-installing-it.html

	rpm2cpio "${REPO_RPM}" | xz -d | cpio -idmv

	# Proceed as long as etc exists

	if [[ -d "etc" && -f "/etc/dnf/dnf.conf" ]]; then

		# copy /etc/dnf/dnf.conf from system
		# dnf still pulls from /etc/yum/yum.repos.d/ for extra configuration

		mkdir -p "${DNF_CONF}"
		cp "/etc/dnf/dnf.conf" "${DNF_CONF}"
		sed -i "s/\$releasever/${RELEASE}/g" ${TMP_DIR}/etc/yum.repos.d/*
		sed -i "s/\$basearcg/${ARCH}/g" ${TMP_DIR}/etc/yum.repos.d/*

		# Enable base repos
		sed -i "s/\enabled\=0/enabled\=1}/g" "${TMP_DIR}/etc/yum.repos.d/fedora.repo"
		sed -i "s/\enabled\=0/enabled\=1}/g" "${TMP_DIR}/etc/yum.repos.d/fedora-updates.repo"

		# Disable GPG check for image build
		sed -i "s/\gpgcheck\=1/gpgcheck\=0}/g" "${TMP_DIR}/etc/yum.repos.d/fedora.repo"
		sed -i "s/\gpgcheck\=2/gpgcheck\=0}/g" "${TMP_DIR}/etc/yum.repos.d/fedora-updates.repo"

		# Add the contents of the repo files to etc/dnf/dnf.conf
		# mkimage-yum.sh only uses the base .conf file to build the repo information
		find etc -name '*.repo' -exec cat {} >> "${DNF_CONF}" \;


	else

		echo -e "\nERROR: Cannot find etc directory or /etc/dnf/dnf.conf!"
		exit 1
	fi


	# Build image
	if ! sudo ./mkimage-yum.sh -y ${DNF_CONF}; then

		echo -e "\nERROR: Failed to create image! Exiting"
		exit 1

	fi

}

# Start script
build_image
