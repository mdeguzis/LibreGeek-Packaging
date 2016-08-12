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

done

sudo apt-get install -y vkquake

# Generate linked lib list

ldd /usr/games/vkquake | cut -d " " -f 3 &> lib-path-only.txt

#################################
# Copy libs to folder
#################################

echo -e "\nUpdating static libs"
sleep 2s

filename="lib-path-only.txt"

while read -r line
do

	name="${line}"
	# echo "Name read from file - ${name}"
	cp -v "${name}" "${PWD}/libs"
   
done < "${filename}"

echo "done!"
