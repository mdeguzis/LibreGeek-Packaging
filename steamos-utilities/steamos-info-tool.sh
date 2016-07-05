#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	steamos-info-tool.sh
# Script Ver:	0.1.3
# Description: Tool to collect some information for troubleshooting
#		release
#
# See:		
#
# Usage:	./steamos-info-tool.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

fuction_set_vars()
{
  
  TOP=${PWD}
  
  DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
  DATE_SHORT=$(date +%Y%m%d)
  
  LOG_FOLDER="/tmp/steamos-logs"
  LOGFILE="${LOG_FOLDER}/steam_info.txt"
  
  STEAM_CLIENT_VER=$(grep "version" /home/steam/.steam/steam/package/steam_client_ubuntu12.manifest) \
  | awk '{print $2}' | sed 's/"//g')
  
}

function_gather_info()
{

  # OS
  echo -e "==================================="
  echo -e "OS Information"
  echo -e "===================================\n"
  lsb_release -a

  echo -e "==================================="
  echo -e "Steam Information"
  echo -e "===================================\n"

  Steam client version: "${STEAM_CLIENT_VER}"

}

function_gather_logs()
{
  
  # Simply copy logs to temp log folder to be tarballed later
	pathlist=()
	pathlist+=("/tmp/dumps/steam_stdout.txt")
  pathlist+=("/home/steam/.steam/steam/package/steam_client_ubuntu12.manifest")
  pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-dpkg.log")
  pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-shutdown.log")
  pathlist+=("/var/log/unattended-upgrades/unattended-upgrades.log")
  pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-shutdown-output.log")
  pathlist+=("/run/unattended-upgrades/ready.json")
  
  for file in "${pathlist[@]}"
  do
    cp ${LOG_FOLDER} ${file}
    
  done
  
  # Notable logs not included right now
  # /home/steam/.steam/steam/logs*
  
}

main()
{
  
  # Set vars
  function_set_vars
  
  # Create log folder if it does not exist
  if [[ !-d "${LOG_FOLDER}" ]]; then
  
    mkdir -p "${LOG_FOLDER}"
    
  fi
  
  # Remove old logs to old folder and clean folder
  mv ${LOG_FOLDER} ${LOG_FOLDER}.old
  rm -rf ${LOG_FOLDER}/*

  echo -e "==================================="
  echo -e "SteamOS Info Tool"
  echo -e "===================================\n"

  # get info about system
  function_gather_info
  
  # Get logs
  function_gather_logs
  
  # Archive log filer with date
  cd ${LOG_FOLDER}
  tar -cvzf "${LOG_FOLDER}_${DATE_SHORT}.tar.gz" "${LOG_FOLDER}"
  cd ${TOP}
  
}

# Main
clear
main &> ${LOGFILE}

cat<<-EOF
Log information: ${LOGFILE}"
echo -n "Web Link to log information: " && cat ${LOGFILE} | curl -F 'sprunge=<-' http://sprunge.us
EOF
