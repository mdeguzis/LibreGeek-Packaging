#!/bin/bash

# Ensure that no matter where the bash script is called from, the path
# is correct to where teh script is called from
cd "$(dirname "${BASH_SOURCE[0]}")"

# Append our pwd to LD_LIBRARY_PATH to handle the current run-path
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./

# Start game
./am2r
