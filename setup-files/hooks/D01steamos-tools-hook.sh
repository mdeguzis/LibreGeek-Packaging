#!/bin/bash

# Add SteamOS tools into chroot environment if we are using a brewmaster DIST

if [[ "$DIST" == "brewmaster" ]]; then
  
  echo "I: STEAMOS-TOOLS: Adding standard SteamOS-Tools repository configuration"
  
  # get repository configuration script and invoke
  wget "https://raw.githubusercontent.com/ProfessorKaos64/SteamOS-Tools/brewmaster/configure-repos.sh" -q -nc
  chmod +x configure-repos.sh
  sed -i "s|sudo ||g" configure-repos.sh
   ./configure-repos.sh &> /dev/null
  
  # Validation check
  repo_files="/etc/apt/sources.list.d/steamos-tools.list \
              /etc/apt/sources.list.d/jessie.list \
              /etc/apt/sources.list.d/jessie-backports.list \
              /etc/apt/preferences.d/steamos-tools \
              /etc/apt/preferences.d/jessie \
              /etc/apt/preferences.d/jessie-backports \
              /etc/apt/apt.conf.d/60unattended-steamos-tools"
  
  # Run validation
  for file in ${repo_files};
  do
    if [[ ! -f "${file}" ]]; then
      echo "E: STEAMOS-TOOLS: Failed to add SteamOS-Tools repository. Exiting"
      exit 1
    fi
  done

  # If we havent exited by now, output pass
  echo "I: STEAMOS-TOOLS: Repository validation [PASSED]"

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
