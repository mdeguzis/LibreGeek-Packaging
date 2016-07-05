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

function_gather_info()
{

  # OS
  echo -e "==================================="
  echo -e "OS Information"
  echo -e "===================================\n"
  lsb_release -a

}

main()
{

  echo -e "==================================="
  echo -e "SteamOS Info Tool"
  echo -e "===================================\n"

  # get info about system
  function_gather_info
}

# Main
clear
main
