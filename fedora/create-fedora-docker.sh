	cd "${TMP_DIR}"

fi

# Set ARCH, REVISION and release and release defaults
# TODO
RELEASE="24
REVISION="3"
ARCH="i386"

# Set vars
RELEASE="$RELEASE_OPT"
REVISION="$REVSION_OPT"
ARCH="$ARCH_OPT"
IMAGE_NAME="Fedora-${RELEASE}-${ARCH}"
BASE_URL="https://kojipkgs.fedoraproject.org/packages/fedora-repos"
REPO_RPM="${BASE_URL}/${RELEASE}/${REVISION}/noarch/fedora-repos-${RELEASE}-${REVISION}.noarch.rpm"
BUILD_SCRIPT="https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-yum.sh"
BASE_PKGS="base base-devel"

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

	mkdir -p "${TMP_DIR}/etc/dnf"
	cp "/etc/dnf/dnf.conf" "${TMP_DIR}/etc/dnf"
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
	find etc -name '*.repo' -exec cat {} >> etc/dnf/dnf.conf\;


else
