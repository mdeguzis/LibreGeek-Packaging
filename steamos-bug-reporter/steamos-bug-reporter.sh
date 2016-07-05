#!/bin/bash

session=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal /org/freedesktop/ConsoleKit/Seat1 org.freedesktop.ConsoleKit.Seat.GetActiveSession)
uid=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal $session org.freedesktop.ConsoleKit.Session.GetUnixUser | tr -s ' ' | cut -d' ' -f3)
xdisplay=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal $session org.freedesktop.ConsoleKit.Session.GetX11Display | tr -d ' ')
username=$(getent passwd $uid | cut -d: -f1)
screenshot=

if [ $username != "desktop" ]; then
  screenshot=$(mktemp --suffix=.png)
  DISPLAY=$xdisplay XAUTHORITY=/home/$username/.Xauthority import -window root $screenshot
  dbus-send --system --print-reply --dest=org.freedesktop.DisplayManager  /org/freedesktop/DisplayManager/Seat0 org.freedesktop.DisplayManager.Seat.SwitchToUser string:'desktop' string:''

  # Wait until the switch to desktop is completed
  newsession=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal /org/freedesktop/ConsoleKit/Seat1 org.freedesktop.ConsoleKit.Seat.GetActiveSession)
  while [ $newsession == $session ]; do
    sleep 1
    newsession=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal /org/freedesktop/ConsoleKit/Seat1 org.freedesktop.ConsoleKit.Seat.GetActiveSession)
  done
  session=$newsession
fi

xdisplay=$(dbus-send --system --dest=org.freedesktop.ConsoleKit --type=method_call --print-reply=literal $session org.freedesktop.ConsoleKit.Session.GetX11Display | tr -d ' ')
DISPLAY=$xdisplay XAUTHORITY=/home/desktop/.Xauthority valve-bugreporter $screenshot
