#!/bin/bash

####################################
# Installation
####################################

# Add SteamOS tools into chroot environment if we are using a brewmaster DIST

if [[ "$DIST" == "brewmaster" ]]; then

	echo "I: STEAMOS-TOOLS: Adding repository configuration"

	# get repository configuration script and invoke
	wget "https://raw.githubusercontent.com/ProfessorKaos64/SteamOS-Tools/brewmaster/configure-repos.sh" -q -nc
	chmod +x configure-repos.sh
	
	# pbuilder will invoke as root, ditch sudo
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
	# Update
	####################################
	
	echo "I: STEAMOS-TOOLS: Updating package listings"
	
	if ! apt-get update -y -q &> /dev/null; then
	
		echo "E: STEAMOS-TOOLS: SteamOS-Tools Update operation failed. Exiting"
		exit 1
	
	fi
	
	####################################
	# Validation
	####################################
	
	# Add standard files to file list
	
	repo_files+=("/etc/apt/sources.list.d/steamos-tools.list")
	repo_files+=("/etc/apt/sources.list.d/jessie.list")
	repo_files+=("/etc/apt/sources.list.d/jessie-backports.list")
	repo_files+=("/etc/apt/preferences.d/steamos-tools")
	repo_files+=("/etc/apt/preferences.d/jessie")
	repo_files+=("/etc/apt/preferences.d/jessie-backports")
	repo_files+=("/etc/apt/apt.conf.d/60unattended-steamos-tools")
	
	# If checking beta, add additioanl files to file list
	
	if [[ "$STEAMOS_TOOLS_BETA_HOOK" == "true" ]]; then
	
		repo_files+=("/etc/apt/sources.list.d/steamos-tools-beta.list")
		repo_files+=("/etc/apt/preferences.d/steamos-tools-beta ")
	
	fi

	# Run validation
	for file in ${repo_files};
	do
		if [[ ! -f "${file}" ]]; then
	
			echo "E: STEAMOS-TOOLS: Repository validation [FAILED]. Exiting."
			exit 1
		else
	
			echo "I: STEAMOS-TOOLS: Repository validation [PASSED]"
	
		fi
	
	done

else
	
	# just output text
	echo "I: STEAMOS-TOOLS: Not applicable to dist ${DIST}"

# END BREWMASTER DIST HANDLING
fi
