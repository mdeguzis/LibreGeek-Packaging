#!/bin/bash

# Prints a list of installed packages on the system and deps
# This script may expand to provide more useful data in the future

# Reset lists

rm -f /tmp/installed_with_deps.txt

get_installed_with_deps()
{

	INSTALLED=$(dpkg -l | awk '{print $1}'
	
	for x in $(cat "$INSTALLED"); 
	do
		apt-cache rdepends $i >> /tmp/installed_with_deps.txt
	done

	less /tmp/intstalled_with_deps.txt

}

show_lists()
{

	cat<<- EOF
	
	==========================
	Generated Lists:
	==========================
	
	EOF
	
	ls /tmp/ | grep -E 'installed_with_deps'

}

menu()
{

	while [[ "$menu_choice" != "x" || "$menu_choice" != "done" ]];
	do
	
		cat<<- EOF
		========================================
		Pacakge management info tool
		========================================
		
		1) Show installed packages, and a list of their dependencies
		x) Exit / done
		
		EOF
	
		# the prompt sometimes likes to jump above sleep
		sleep 0.5s
		
		read -ep "Choice: " menu_choice
		
		case "$menu_choice" in
			        
			1)
			get_installed_with_deps
			;;
			
			x|done)
			break
			;;
			
		esac
		
	done

}

# start script
menu
