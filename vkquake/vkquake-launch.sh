#!/bin/bash

# Since SteamOS "add library shortcut" can't handle spaces, we need
# This launcher file
# See: https://github.com/ValveSoftware/SteamOS/wiki/Working-with-non-Steam-games

# Quakespasm / vkquake expects ${PWD} when launching
# Place files in /usr/share/quake, as other engines often expect
# Try to handle some logic for this...

DEFAULT_BASE_DIR=/usr/share/quake

if [[ -d "${DEFAULT_BASE_DIR}" ]];  then

	BASE_DIR="${DEFAULT_BASE_DIR}"

else

	BASE_DIR="${PWD}"

fi

# Launch game with -basedir

/usr/games/vkquake -basedir "${BASE_DIR}"
