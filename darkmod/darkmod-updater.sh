#!/bin/bash

funct_set_vars()
{

	UPDATER_URL="http://www.fidcal.com/darkuser/"
	UPDATER_ZIP="tdm_update_linux.zip"
	UPDATER_FILE="tdm_update.linux"

	# check if we are runnign SteamOS or not.
	# Since / is normally only 10 GB, we will not install a multi-GB folder set there
	OS=$(lsb_release -is)
	DEBIAN=$(uname -a | grep Debian)

	if [[ "${OS}" == "SteamOS" ]]; then

	  # create any dirs needed and set command
	  echo -e "Detected SteamOS"
	  GAME_DIR="/home/steam/darkmod"
	  COMMAND="sudo -u steam"

	elif [[ "${DEBIAN}" != "" ]]; then

	  echo -e "Detected Other Debian OS"
	  GAME_DIR="/usr/share/games/darkmod"

	else

	echo -e "Detected incompatible OS. Exiting"
	exit 1

	fi

	# create game directory
	mkdir -p "${GAME_DIR}"

	# clean up any old updater files

	rm -f "${GAME_DIR}/${UPDATER_ZIP}"
	rm -f "${GAME_DIR}/${UPDATER_FILE}"

}

funct_download_updater()
{

	# get updater for latest release

	echo -e "\nDownloading the latest Dark Mod updater...\n"
	sleep 2s

	sudo wget -O "${GAME_DIR}/${UPDATER_ZIP}" "${UPDATER_URL}/${UPDATER_ZIP}" -q --show-progress -nc
	sudo unzip -d "${GAME_DIR}" "${GAME_DIR}/${UPDATER_ZIP}"
	sudo chmod +x "${GAME_DIR}/${UPDATER_FILE}"

}

funct_links()
{
	
	# Link the proper game dir(s)
	LINK_DEST="/usr/games/darkmod/darkmod"
	OS=$(lsb_release -is)
	
	# evaluate
	if [[ "${OS}" == "SteamOS" ]]; then
	
		LINK_TARGET="/home/steam/darkmod/thedarkmod.x86"
		
	else
		LINK_TARGET="/usr/share/games/darkmod/thedarkmod.x86"
		
	fi

	# Link
	echo -e "\nLinking correct directory / executable\n"
	sudo ln -s ${LINK_TARGET} ${LINK_DEST}
	
}

funct_run_updater()
{
	
	# If updater does not exist, fetch
	if [[ ! -f "${GAME_DIR}/${UPDATER_FILE}" ]]; then
	
		# get updater
		funct_download_updater
		
	fi

	echo -e "\nRunning updater in game dir: $GAME_DIR\n"
	sleep 3s

	# Enter updater directory
	cd ${GAME_DIR} || exit

	if [[ "${OS}" == "SteamOS" ]]; then

		# Run updater as user "steam"
		echo -e "Running updater as user 'steam'\n"
		sudo -u steam ./${UPDATER_FILE} ${OPTIONS}

	elif [[ "${DEBIAN}" != "" ]]; then

		# Elevated rights are needed to write to /usr/share/games/darkmod
		sudo ./${UPDATER_FILE} ${OPTIONS}

	fi

}

funct_menu()
{
	
	###################################
	# Available arguments (info)
	###################################
	# See: tdm/tdm_update/libtdm_update/Updater/UpdaterOptions.h
	# Source: https://github.com/ProfessorKaos64/tdm
	
	# --proxy [arg], Use a proxy to connect to the internet, example --proxy=http://user:pass@proxy:port
	# --targetdir [arg],The folder which should be updated.
	# --help, Display this help page
	# --keep-mirrors, Don't download updated mirrors list from the server, use local one.
	# --keep-update-packages, Don't delete downloaded update packages after applying them.
	# --noselfupdate, Don't perform any special 'update the updater' routines.
	# --dry-run, Don't do any updates, just perform checks.

	###################################
	# Start web app addition loop
	###################################
	clear
	
	while [[ "$choice" != "e" ]];
	do	

		cat<<-EOF
		####################################################
		The Dark Mod Updater Wrapper for Debian GNU/Linux
		####################################################
		Please choose which action you wish to perform.

		(1) -- Run updater --
		(2) Dry Run (perform checks/tests only)
		(3) Run updater, but use local download mirrors
		(4) Run updater, Keep update packages afterwards
		(5) Run updater, but specify your own game folder
		(6) Obtain latest DarkMod Updater file
		(h) Show help file for tdm_update
		(e) Exit / Done

		EOF

		# the prompt sometimes likes to jump above sleep
		sleep 0.5s

		read -erp "Choice: " choice

		case "$choice" in
		
		1)
		OPTIONS="--noselfupdate"
		funct_run_updater
		funct_cleanup
		;;

		2)
		OPTIONS="--dry-run"
		funct_run_updater
		funct_cleanup
		;;
		
		3)
		OPTIONS="--keep-mirrors"
		funct_run_updater
		funct_cleanup
		;;

		4)
		OPTIONS="--keep-update-packages"
		funct_run_updater
		funct_cleanup
		;;
		
		5)
		read -erp "Directory to update: " UPDATE_DIR
		OPTIONS="--targetdir ${UPDATE_DIR}"
		funct_run_updater
		funct_cleanup
		;;

		6)
		OPTIONS=""
		funct_download_updater
		;;
		
		h)
		OPTIONS="--help"
		funct_run_updater
		;;

		e)
		echo -e "\nExiting\n"
		exit 1
		;;

		*)
		echo -e "\n==ERROR==\nInvalid Selection!\n"
		sleep 1s
		continue
		;;
		esac

	done

}

funct_cleanup()
{

	echo -e "\nRunning cleanup\n"
	sleep 2s

	if [[ "${OS}" == "SteamOS" ]]; then

		# Fix owner, perms on GAME_DIR
		chown -R steam:steam ${GAME_DIR}

	fi
	
}

# Start script
funct_set_vars
funct_menu
funct_cleanup
funct_links
