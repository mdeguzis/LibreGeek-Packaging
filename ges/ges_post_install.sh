#!/bin/bash

###############
# Status
################

# This is a tricky situation
# The build currently assumes CMAKE_INSTALL_PREFIX points to the gessource folder
# This makes a build difficult from a packaging perspective until more is known.

# For now, the libs (even though they install into CMAKE_INSTALL_PREFIX/bin),
# will be moved post-install, into the gesource directory (if it exists).
# If the suggested location does not exist, a quick search will commence.
# If gesource cannot be found, the user will be notified to move the files later.

detect_source_sdk()
{

	# TODO
	# This comoponent is necessary for install
	# If this is not installed, it is more than likely the sourcemods folder will not exist
	# ID 211 is "Source SDK", which defaults to 2013
	# See: https://steamdb.info/search/?a=app&q=Source+SDK

	SOURCE_SDK_2006_DL="steam://run/215"
	SOURCE_SDK_2007_DL="steam://run/218"
	SOURCE_SDK_2013_DL="steam://run/211"

	SOURCE_SDK_DL="${SOURCE_SDK_2007_DL}"
	SOURCE_SDK_DIR="TODO-LOCATION"

	# Not sure if this will work, but this shortcut may prompt installation:
	if [[ "${SOURCE_SDK_DIR}" == "" ]]; then

		# install Source SDK 2007
		if ! ${SOURCE_SDK_DL}; then

			echo -e "Failed to install Source SDK!. Please uninstall this package.\n"
		fi

	fi

}

gesource_auto_find()
{

	# Check for common locations of gesource
	echo -e "\ngesource folder not found in typical locations, searching...\n"
	
	if [[ "${OS}" == "SteamOS" ]]; then

		GESOURCE_DIR=$(find /home/steam -type d -name "gesource")

	else

		GESOURCE_DIR=$(find ${HOME} -type d -name "gesource")

	fi

}

main()
{

	# Set backup dir
	BACKUP_DIR="${HOME}/ges-backup"
	mkdir -p "${BACKUP_DIR}"

	# Detect OS (allow installation on Debian systems, non-standard to SteamOS)
	if which lsb_release &> /dev/null; then

		OS=$(lsb_release -si)

	else

		OS=$(cat /etc/os-release | grep -w "NAME" | cut -d'=' -f 2)

	fi

	# Check location/existance of gesource directory
	if [[ "${OS}" == "SteamOS" ]]; then

		GESOURCE_DIR="/home/steam/.local/share/Steam/steamapps/sourcemods/gesource"

	elif [[ "${OS}" == "Debian" ]]; then

		GESOURCE_DIR="${HOME}/.local/share/Steam/steamapps/sourcemods/gesource"

	else

		gesource_auto_find

	fi

	# Make sure GESOURCE_DIR isn't blank
	if [[ "${GESOURCE_DIR}" == "" ]]; then

		echo -e "\nFailed to find gesource directory! Please uninstall this package.\n"
		sleep 2s
		exit 1

	else

		# backup first
		cp "/usr/bin/client.so" "${BACKUP_DIR}"
		cp "/usr/bin/server.so" "${BACKUP_DIR}"

		sudo mv "/usr/bin/client.so" "${GESOURCE_DIR}"
		sudo mv "/usr/bin/server.so" "${GESOURCE_DIR}"

		echo -e "\nclient.so and server.so moved to ${GESOURCE_DIR}"
		echo -e "Files backed up to: ${BACKUP_DIR}"
		sleep 2s

	fi

}
