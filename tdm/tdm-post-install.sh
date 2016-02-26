!#/bin/bash

echo -e "\m==> Now running post install steps"

# get updater for latest release

echo "\nDownloading The Dark Mod updater...\n"
sleep 2s
wget -P "/tmp/tdm_update.linux.zip" "http://www.fidcal.com/darkuser/tdm_update.linux.zip" -q -nc --show-progress
unzip "/tmp/tdm_update.linux.zip"
chmod +x "tdm_update.linux"

echo "\nCopying The Dark Mod updater to /usr/share/games/tdm/tdm_update.linux"
sudo cp "tdm_update.linux" "/usr/share/games/tdm"

echo "\n...Running The Dark Mod updater\n"
cd "/usr/share/games/tdm"
./tdm_update.linux
