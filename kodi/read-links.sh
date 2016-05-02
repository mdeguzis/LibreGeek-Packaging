#!/bin/bash

# Reads and resolves symbolic links

depth="$1"

if [[ "${depth}" == "" ]]; then
  depth="1"
fi

find . -maxdepth $depth -type l | while read LINE; 
do 
  echo link: $LINE resolved: `readlink $LINE`
done
