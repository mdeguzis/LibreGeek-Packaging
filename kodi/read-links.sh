#!/bin/bash

# Reads and resolves symbolic links

depth="$1"
echo ""

if [[ "${depth}" == "" ]]; then
  depth="1"
fi

find . -maxdepth $depth -type l | while read LINE; 
do
  ORIG=$(echo ${LINE})
  ACTUAL_FILE=$(realpath ${LINE})
  cp --remove-destination "${ACTUAL_FILE}" "${ORIG}"
  echo "Resolved link:" "${LINE}" && sleep 0.3s
done

echo ""
