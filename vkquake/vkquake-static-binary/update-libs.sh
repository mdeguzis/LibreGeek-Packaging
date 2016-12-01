#!/bin/bash

#################################
# Updates libs/ folder
#################################

TYPE="$1"

echo -e "\n==> Updating package listsings\n"
sleep 2s
sudo apt-get update

# Prereqs

if [[ ! -d "libs" || ! -d "libs-all" ]]; then

	mkdir libs 2> /dev/null
	mkdir libs-all 2> /dev/null

fi

# Generate libs list from build host

if sudo apt-get install -y --force-yes vkquake &> /dev/null; then

	echo -e "Package: vkquake [OK]"

else

	# echo and exit if package install fails
	echo -e "Package: vkquake [FAILED] Exiting..."
	exit 1

fi

sudo apt-get install -y vkquake

# Generate linked lib list

ldd /usr/games/vkquake | cut -d " " -f 3 &> libs-all.txt

#################################
# Copy libs to folder
#################################

if [[ "${TYPE}" == "all" ]]; then

	# clean out old libs
	rm -r libs-all/*

	echo -e "\nUpdating static libs"
	sleep 2s

	file="libs-all.txt"

	while IFS= read -r line
	do
		#echo "$var"
		cp -v "${line}" "${PWD}/libs-all"

	done < "$file"

	echo "done!"

else

	cat<<- 
	
	Script requires an argument!
	Availble: [all]

	EOF

fi
