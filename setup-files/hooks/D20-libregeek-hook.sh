#!/bin/bash

####################################
# LibreGeek DIST handling
####################################

# Test OS first, so we can allow configuration on multiple distros
# If lsb_release is not present, use alternative method
# Check for OS, since we can add PPA's just based on Ubuntu

if which lsb_release &> /dev/null; then

	OS=$(lsb_release -si)

else

	OS=$(cat /etc/os-release | grep -w "ID" | cut -d "=" -f 2)

fi

if [[ "${OS}" == "SteamOS" ]]; then

	echo "I: STEAMOS-TOOLS: Adding repository configuration"

	# get repository configuration script and invoke
	wget "https://raw.githubusercontent.com/ProfessorKaos64/SteamOS-Tools/brewmaster/configure-repos.sh" -q -nc
	chmod +x configure-repos.sh

	sed -i 's/sudo //g' configure-repos.sh

	# No need to update twice (if beta is flagged, update will have to run again)
	# Remove any sleep commands to speed up process
	sed -i '/apt-get update/d' configure-repos.sh
	sed -i '/sleep/d' configure-repos.sh

	# Run setup
	if ! ./configure-repos.sh &> /dev/null; then
		echo "E: STEAMOS-TOOLS: SteamOS-Tools configuration [FAILED]. Exiting."
		exit 1
	fi

	if [[ "$STEAMOS_TOOLS_BETA_HOOK" == "true" ]]; then

		echo "I: STEAMOS-TOOLS: Adding SteamOS-Tools beta track"

		# Get this manually so we only have to update package listings once below
		wget "http://packages.libregeek.org/steamos-tools-beta-repo.deb" -q -nc

		if ! dpkg -i "steamos-tools-beta-repo.deb" &> /dev/null; then
			echo "E: STEAMOS-TOOLS: Failed to add SteamOS-Tools beta repository. Exiting"
			exit 1
		fi

	# END BETA REPO HANDLING
	fi

	####################################
	# Validation
	####################################

	# Add standard files to file list
	REPO_FILES+=("/usr/share/keyrings/libregeek-archive-keyring.gpg")
	REPO_FILES+=("/etc/apt/sources.list.d/steamos-tools.list")
	REPO_FILES+=("/etc/apt/sources.list.d/jessie.list")
	REPO_FILES+=("/etc/apt/apt.conf.d/60unattended-steamos-tools")

	# If checking beta, add additioanl files to file list
	if [[ "$STEAMOS_TOOLS_BETA_HOOK" == "true" ]]; then

		REPO_FILES+=("/etc/apt/sources.list.d/steamos-tools-beta.list")

	fi

	# If we are using the beta hook, and not nixing apt-prefs
	if [[ "$STEAMOS_TOOLS_BETA_HOOK" == "true" && "$NO_APT_PREFS" != "true" ]]; then

		REPO_FILES+=("/etc/apt/preferences.d/steamos-tools-beta ")

	fi

	# if apt-pres ifs removed, don't check these files
	if [[ "$NO_APT_PREFS" != "true" ]]; then

		REPO_FILES+=("/etc/apt/preferences.d/steamos-tools")
		REPO_FILES+=("/etc/apt/preferences.d/jessie")
		REPO_FILES+=("/etc/apt/preferences.d/jessie-backports")

	fi

	# Run validation
	for FILE in "$REPO_FILES";
	do
		if [[ ! -f "$FILE" ]]; then

			echo "E: STEAMOS-TOOLS: Repository validation [FAILED]. Exiting."
			echo "E: Failed on: $FILE"
			exit 1
		else

			echo "I: STEAMOS-TOOLS: Repository validation [PASSED]"

		fi

	done

elif [[ "${OS}" == "Debian" || "${OS}" == "debian" ]]; then


	echo "I: LIBREGEEK: Adding Debian repository configuration"

	# Get repo package(s)
	wget "http://packages.libregeek.org/libregeek-archive-keyring.deb" -q -nc
	wget "http://packages.libregeek.org/libregeek-debian-repo.deb" -q -nc

	# Install repo packages
	dpkg -i libregeek-archive-keyring.deb &> /dev/null
	dpkg -i libregeek-debian-repo.deb &> /dev/null

	REPO_FILES+=()
	REPO_FILES+=("/etc/apt/sources.list.d/libregeek-debian-repo.list")
	REPO_FILES+=("/usr/share/keyrings/libregeek-archive-keyring.gpg ")

	# Run validation
	for FILE in "$REPO_FILES";
	do
		if [[ ! -f "$FILE" ]]; then

			echo "E: LIBREGEEK: Repository validation [FAILED]. Exiting."
			echo "E: Failed on: $FILE"
			exit 1
		else

			echo "I: LIBREGEEK: Repository validation [PASSED]"

		fi

	done

	if [[ "$DEBIAN_TESTING" == "true" ]]; then

		echo "I: LIBREGEEK: Adding LibreGeek Debian testing repository"

		# Get this manually so we only have to update package listings once below
		wget "http://packages.libregeek.org/libregeek-debian-testing-repo.deb" -q -nc

		if ! dpkg -i "jessie-testing.deb" &> /dev/null; then
			echo "E: LIBREGEEK: Failed to add LibreGeek Debian testing repository. Exiting"
			exit 1
		fi

	fi

	if [[ "$DEBIAN_BACKPORTS" == "true" ]]; then

		echo "I: LIBREGEEK: Adding LibreGeek Debian backports repository"

		# Get this manually so we only have to update package listings once below
		# The LibreGeek repo should only contain backports above jessie-backports upstream
		# so we do not supercede them.
		wget "http://packages.libregeek.org/libregeek-debian-backports-repo.deb" -q -nc

		# Debian backports should already by enabled by default, if it fails the test, install
		if grep "jessie-backports" "/etc/apt/sources.list"; then

			wget "http://packages.libregeek.org/debian-backports-repo.deb" -q -nc

			echo "I: LIBREGEEK: Adding Debian backports repository"

                	if ! dpkg -i "debian-backports-repo.deb" &> /dev/null; then

				echo "E: LIBREGEEK: Failed to add Debian backports repository. Exiting"
				exit 1

			fi

		fi

		# Always add our backport list
		if ! dpkg -i "libregeek-debian-backports-repo.deb" &> /dev/null; then
			echo "E: LIBREGEEK: Failed to add LibreGeek Debian backports repository. Exiting"
			exit 1
		fi

	fi

elif [[ "${OS}" == "Ubuntu" || "${OS}" == "ubuntu" ]]; then

	echo "I: LIBREGEEK: Checking for required PPA prereqs"

	# ensure required packages are installed
	apt-get install -y software-properties-common python-software-properties &> /dev/null

	# Add repo configuration
	# Try to copy/rebuild over packages from other PPA instead of add more repos
	echo "I: LIBREGEEK: Adding PPA repository configuration"
	add-apt-repository -y ppa:mdeguzis/libregeek &> /dev/null

	#echo "I: LIBREGEEK: Adding PPA repository configuration (toolchain)"
	#add-apt-repository -y ppa:mdeguzis/libregeek-toolchaina &> /dev/null

fi

####################################################
# Extra conditions for old distirbution releases
####################################################

if [[ "${DIST}" == "precise" || "${DIST}" == "trusty" ]]; then

	# Add toolchains for older dists
	# llvm toolchains (3.4+), gcc-5, and gcc-6 should suffice for now

	echo "I: LIBREGEEK: Adding PPA jonathonf/llvm (toolchain)"
	add-apt-repository -y ppa:jonathonf/llvm &> /dev/null

	echo "I: LIBREGEEK: Adding PPA jonathonf/gcc-5.4 (toolchain)"
	add-apt-repository -y ppa:jonathonf/gcc-5.4 &> /dev/null

	echo "I: LIBREGEEK: Adding PPA jonathonf/gcc-6.2 (toolchain)"
	add-apt-repository -y ppa:jonathonf/gcc-6.2 &> /dev/null

fi
