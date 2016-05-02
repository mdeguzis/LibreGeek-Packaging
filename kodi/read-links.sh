#!/bin/bash

find . -maxdepth 1 -type l | while read LINE; 
do 
  echo link: $LINE resolved: `readlink $LINE`
done
