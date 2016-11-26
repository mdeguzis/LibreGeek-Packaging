#!/bin/bash

####################################
# Installation
####################################


if [[ "$DIST" == "brewmaster" ]]; then

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
		wget "http://packages.libregeek.org/steamos-tools-beta-repo-latest.deb" -q -nc
		
		if ! dpkg -i "steamos-tools-beta-repo-latest.deb" &> /dev/null; then
			echo "E: STEAMOS-TOOLS: Failed to add SteamOS-Tools beta repository. Exiting"
			exit 1
		fi

	# END BETA REPO HANDLING
	fi

	####################################
	# Validation
	####################################
	
	# Add standard files to file list
	REPO_FILES+=("/usr/share/keyrings/libregeek-archive-keyring.gpg ")
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

elif [[ "$DIST" == "jessie" ]]; then

	# Get repo package(s)
	wget "http://packages.libregeek.org/libregeek-archive-keyring-latest.deb" -q -nc
	wget "http://packages.libregeek.org/libregeek-debian-repo-latest.deb" -q -nc

	# Install repo packages
	dpkg -i libregeek-archive-keyring-latest.deb &> /dev/null
	dpkg -i libregeek-debian-repo-latest.deb &> /dev/null

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

else

	# just output text
	echo "I: LIBREGEEK: Not applicable to dist ${DIST}"

# END BREWMASTER DIST HANDLING
fi
