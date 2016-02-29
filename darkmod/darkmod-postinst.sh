#!/bin/bash

UPDATER_URL="http://www.fidcal.com/darkuser/"
UPDATER_ZIP="tdm_update_linux.zip"
UPDATER_FILE="tdm_update.linux"
OPTIONS="--noselfupdate"

# check if we are runnign SteamOS or not.
# Since / is normally only 10 GB, we will not install a multi-GB folder set there
OS=$(lsb_release -is)
DEBIAN=(uname -a | grep Debian)

if [[ "${OS}" == "SteamOS" ]]; then

  # create any dirs needed
  echo -e "Detected SteamOS"
  GAME_DIR="/home/steam/darkmod"

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

echo -e "\n==> Now running post install steps"
sleep 2s

# get updater for latest release

echo -e "\nDownloading The Dark Mod updater...\n"
sleep 2s

wget -O "${GAME_DIR}/${UPDATER_ZIP}" "${UPDATER_URL}/${UPDATER_ZIP}" -q --show-progress -nc
unzip -d "${GAME_DIR}" "${GAME_DIR}/${UPDATER_ZIP}"
chmod +x "${GAME_DIR}/${UPDATER_FILE}"

# run updater
# total size sould be ~2.61 GB

###################################
		# Start web app addition loop
		###################################
		
		while [[ "$web_app_choice" != "9" || "$web_app_choice" != "done" ]];
		do	
		
		  cat<<-EOF
			#############################################################
			The Dark Mod Updater Wraper for Debian GNU/Linux
			#############################################################
	    Please choose which webapp you wish to add. Choose Done when finished."
		  (1) Updater / Install game files
			
			EOF
			
			# the prompt sometimes likes to jump above sleep
			sleep 0.5s
			
			read -ep "Choice: " choice
			
			case "$choice" in
			        
			        1)
			        echo -e "\nRunning updater in game dir: ${GAME_DIR}\n"
              cd ${GAME_DIR} || exit
              ./${UPDATER_FILE} ${OPTIONS}
			        kiosk_opt="/usr/bin/$LAUNCHER"
			        ;;
			        

			         
			        *)
			        echo -e "\n==ERROR==\nInvalid Selection!"
			        sleep 1s
			        continue
				;;
			esac

echo -e "\nRunning cleanup\n"
sleep 2s

if [[ "${OS}" == "SteamOS" ]]; then

  # Fix owner, perms on GAME_DIR
  chown -R steam:steam ${GAME_DIR}
 
fi
