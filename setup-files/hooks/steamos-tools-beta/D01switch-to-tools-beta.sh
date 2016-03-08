#!/bin/bash

echo "Switching to SteamOS-Tools beta track"
sleep 3s
apt-get install steamos-tools-beta-repo
apt-get update
