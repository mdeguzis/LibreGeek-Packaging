#!/bin/bash

#DoomRL mp3 to ogg vorbis music conversion script by Cyber Killer
#run this in the games directory

mv ./musichq.lua ./musichq.lua.bak
cat ./musichq.lua.bak | sed -e 's/mp3/ogg/g' > ./musichq.lua
mkdir ./ogg
cd ./mp3
for i in `find . -name '*.mp3'`; do ffmpeg -i $i -vn -acodec libvorbis ../ogg/`echo $i | sed -e 's/\.mp3/\.ogg/'`; done
cd ..

mv ./soundhq.lua ./soundhq.lua.bak
cat ./soundhq.lua.bak | sed -e 's/wav/ogg/g' > ./soundhq.lua
mkdir ./ogghq
cd ./wavhq
for i in `find . -name '*.wav'`; do ffmpeg -i $i -vn -acodec libvorbis ../ogghq/`echo $i | sed -e 's/\.wav/\.ogg/'`; done
cd ..
