#!/bin/bash

# Add SteamOS tools into chroot environment if we are using a brewmaster DIST

if [[ "$DIST" == "brewmaster" ]]; then
  
  echo "I: STEAMOS-TOOLS: Adding standard SteamOS-Tools repository configuration"
  
  # get repository configuration script and invoke
  wget https://raw.githubusercontent.com/ProfessorKaos64/SteamOS-Tools/brewmaster/configure-repos.sh -q -nc
  chmod +x configure-repos.sh
  sed -i "s|sudo ||g" configure-repos.sh
  
  # Invoke script, bail out if it fails
  if ! ./configure-repos.sh &> /dev/null; then
    echo "E: STEAMOS-TOOLS: Failed to add SteamOS-Tools repository. Exiting"
    exit 1
  fi
  
  if [[ "$STEAMOS_TOOLS_BETA_HOOK" == "true" ]]; then
  
    echo "I: NOTICE: Switching to SteamOS-Tools beta track"
    sleep 3s
    
    # Add repository quietly, to reduce output on screen.
    if ! apt-get install -q -y --force-yes steamos-tools-beta-repo; then
      echo "E: STEAMOS-TOOLS: Failed to add SteamOS-Tools beta repository. Exiting"
      exit 1
    fi
    
    if ! apt-get update -q; then
      echo "E: STEAMOS-TOOLS: SteamOS-Tools Update operation failed. Exiting"
      exit 1
    fi

  fi
  
fi
