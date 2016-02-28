#!/bin/bash

##############################
# Launcher for The Dark Mod
##############################
# Note: 'thedarkmod' is a symbolic link to the true location
#       defined by issuing 'ls -la /usr/games/thedarkmod'

# Change directory to launcher symbolic link
cd "/usr/games"

##############################
# Sound
##############################
# Audio lag in The Dark Mod can be unpredictable in the game
# This is most evident at the start screen (menu music)
# Below are some options that may help you.
# COMMENT OUT all other options besides the one you chooose!

#################
# DEFAULT
#################

# Option 1: suspend pulse audio temporarily for the game to use ALSA freely
# For most people, this works. If the lag returns, try restarting the game

pasuspender ./thedarkmod

#################
# Option 2: 
#################

# use aoss to minimize the problem of Pulse Audio monopolising /dev/dsp

# aoss ./thedarkmod

#################
# Option 3: 
#################

# vSet the latency for Pulseaudio
# This generally doesn't work, but may work for you

# export PULSE_LATENCY_MSEC=60; ./thedarkmod.x86

##############################
# Sound (Advanved)
##############################
# These options can be attempted if all else fails
# They can be used in ADDITION to the option set above
# Thse will modify (on the fly) the options in the Darkmod.cfg config file

##############################
# External links for help
##############################

# http://forums.thedarkmod.com/
# http://forums.thedarkmod.com/topic/17414-how-to-configure-the-sound-system-on-linux/
# http://forums.thedarkmod.com/topic/15299-solved-audio-lag-linux-mint-15-64bit/
