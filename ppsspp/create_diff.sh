#!/bin/bash
# -------------------------------------------------------------------------------
# Author: 	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt Name:	create_diff.sh
# Script Ver:	1.0.0
# Description:	Creates a diff file off ppsspp git master and the PPA latest git
#               package for Ubuntu 15.10. For whatever reason, many file
#               differences exist between the two.
#
# Usage:	./create_diff.sh
# -------------------------------------------------------------------------------

# examples
# diff -r dir1 dir2 | grep dir1 | awk '{print $4}' > difference1.txt
# diff -r dir1 dir2 shows which files are only in dir1 and those only in dir2
# diff -r dir1 dir2 | grep dir1 shows which files are only in dir1

main()
{

  echo -e "\n==> Downloading sources\n"
  sleep 2s
  
  # Download sources
  git clone https://github.com/hrydgard/ppsspp git_source
  wget https://launchpad.net/~ppsspp/+archive/ubuntu/testing/+files/ppsspp_*ubuntu15.10.1.tar.xz -C ppa_source
  
  # run diff to file
  
  echo -e "\n==> Creating diff as $pwd/source_differences.txt\n"
  sleep 2s
  
  diff -r git_source ppa_source | grep git_source | awk '{print $4}' > source_differences.txt
  
  echo -e "\n==> Copy missing files? (y/n/exit)"
  sleep .3s
  read -erp "Choice: " copy_choice
  
  if [[ "$copy_choice" == "y" ]]; then
  
    while [[ "$copy_choice" != "done" ]];
    		do
    
          # prompt for choice
    			echo -e "\nMake a selection"
    			echo "(1) Copy file"
    			echo "(2) Copy directory"
    			echo "(3) Abort (keep files)"
    
  			  case "$file" in
  			  
  			  1)
  			  ls -la && echo ""
  			  read -erp "File to copy: " file
  			  cp $file .
  			  ;;
  			  
  			  2)
  			  ls -la && echo ""
  			  read -erp "Folder to copy: " folder
  			  cp -r $folder
  			  ;;
  			  
  			  done)
  			  go_to_cleanup
          ;;
        
        esac
  
  elif [[ "$copy_choice" == "exit" ]]; then
   
    exit 1
   
  else
  
    go_to_cleanup
    
  fi
  
}

go_to_cleanup()
{

  echo -e "\n==> Cleanup\n"
  sleep 2s
  
  # remove source directories
  rm -rf git_source ppa_source
  
}

# Start main
main
