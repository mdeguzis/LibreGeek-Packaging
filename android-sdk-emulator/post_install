#!/bin/bash

cat<<-EOF
=====================================================
WARNING!
=====================================================
This post install must be run from a GUI desktop
session!. It cannot be ran in a pure-CLI environment.
Press CTRL+C to interrupt this step and install
the package when you are withing your dekstop GUI.

Press enter to continue
EOF

read -e ENTER_DUMMY

# Set dirs
ANDROID_HOME="${HOME}/android-sdk"
mkdir -p "${ANDROID_HOME}"

# Determine laest Linux archive

LATEST_VER=$(curl -s http://developer.android.com/sdk/index.html | \
html2text | grep Linux | grep sdk | awk '{print $2}')

# Set target
TARGET_URL="http://dl.google.com/android/android-${LATEST_VER}linux.tgz"

# Get source
wget -P "${ANDROID_HOME}" "${TARGET_URL}" -q -nc --show-progress

# Extract
tar -xzf "android-${LATEST_VER}linux.tgz" -C "${ANDROID_HOME}"

# Kick off installation
${ANDROID_HOME}/android-sdk-linux/tools/android 

# Cleanup
rm -f "android-${LATEST_VER}linux.tgz"

# TODO:
# Add the Android path into .bashrc
# export PATH=${PATH}:~/android-sdk-linux/tools
# export PATH=${PATH}:~/android-sdk-linux/platform-tools
