#!/bin/sh
export XBMC_HOME=/opt/openpht/share/XBMC
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openpht/bin/system/players/dvdplayer/
#Use export AE_ENGINE=SOFT to disable pulse audio
#export AE_ENGINE=SOFT
/opt/openpht/bin/plexhometheater
