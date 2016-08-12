#!/bin/bash

#################################
# Updates libs/ folder
#################################

# Prereqs

if [[ ! -d "libs" ]]; then

	mkdir libs

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

ldd /usr/games/vkquake | cut -d " " -f 3 &> lib-path-only.txt

#################################
# Copy libs to folder
#################################

echo -e "\nUpdating static libs"
sleep 2s

file="lib-path-only.txt"

while IFS= read -r line
do
	#echo "$var"
	cp -v "${line}" "${PWD}/libs"

done < "$file"


echo "done!"