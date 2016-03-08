#!/bin/bash

# Add SteamOS tools into chroot environment

echo "Adding SteamOS-Tools repository configuration"
sleep 3s

# get repository configuration script
wget https://raw.githubusercontent.com/ProfessorKaos64/SteamOS-Tools/brewmaster/configure-repos.sh
chmod +x configure-repos.sh
sed -i "s|sudo ||g" configure-repos.sh
./configure-repos.sh

if [[ "$REPO_BETA_HOOK" == "true" ]]; then

  echo "Switching to SteamOS-Tools beta track"
  sleep 3s
  apt-get install steamos-tools-beta-repo
  apt-get update
  
fi
