#!/bin/bash

####################################
# Installation
####################################

# Add SteamOS beta packages into chroot environment

if [[ "$STEAMOS_BETA" == "true" ]]; then

	echo "I: STEAMOS: Adding Valve SteamOS Beta Repository"

	# Add repository quietly, to reduce output on screen.
	if ! apt-get install -y --force-yes steamos-beta-repo &> /dev/null; then

		echo "E: STEAMOS: Failed to add SteamOS beta repository. Exiting"
		exit 1

	fi

fi

####################################
# Update
####################################

echo "I: STEAMOS: Updating package listings"

if ! apt-get update &> /dev/null; then

	echo "E: STEAMOS: SteamOS update operation failed. Exiting"
	exit 1

fi

####################################
# Validation
####################################

# Add standard files to file list

repo_files+=("/etc/apt/sources.list.d/steamos-beta-repo.list")

# Run validation
for file in ${repo_files};
do
	if [[ ! -f "${file}" ]]; then

		echo "E: STEAMOS: Repository validation [FAILED]. Exiting."
		exit 1
	else

		echo "I: STEAMOS: Repository validation [PASSED]"

	fi

done
