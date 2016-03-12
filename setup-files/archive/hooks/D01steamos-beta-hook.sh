#!/bin/bash

# NO LONGER USED
# Worked into .pbuilderrc
# Former name: D01steamos-beta-hook.sh

####################################
# Installation
####################################

# Add SteamOS beta packages into chroot environment

if [[ "$STEAMOS_BETA" == "true" ]]; then

	echo "I: STEAMOS-BETA: Adding Valve SteamOS Beta Repository"

	# Add repository quietly, to reduce output on screen.
	if ! apt-get install -y --force-yes steamos-beta-repo &> /dev/null; then

		echo "E: STEAMOS-BETA: Failed to add SteamOS beta repository. Exiting"
		exit 1

	fi

fi

####################################
# Update
####################################

echo "I: STEAMOS-BETA: Repairing any half-installed packages"

# attempt to clean up any half-installed packages (unpacked but failed to configure,
# possibly because it was upgraded during shutdown)

if ! apt-get install &> /dev/null; then

	echo "E: STEAMOS-BETA: SteamOS package repair operation failed. Exiting"
	exit 1

fi

echo "I: STEAMOS-BETA: Updating package listings"

if ! apt-get update -y -q &> /dev/null; then

	echo "E: STEAMOS-BETA: SteamOS update operation failed. Exiting"
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

		echo "E: STEAMOS-BETA: Repository validation [FAILED]. Exiting."
		exit 1
	else

		echo "I: STEAMOS-BETA: Repository validation [PASSED]"

	fi

done

####################################
# Upgrade
####################################

echo "I: STEAMOS-BETA-BETA: Upgrading packages"

if ! unattended-upgrade &> /dev/null; then

	echo "E: STEAMOS-BETA: SteamOS upgrade operation failed. Exiting"
	exit 1

fi
