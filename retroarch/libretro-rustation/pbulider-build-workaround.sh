#!/bin/bash

# There are issues updating the cargo index using pdebuild.
# See: https://github.com/rust-lang/cargo/issues/2492

# Login to the chroot and do build there
mkdir -p temp_results
sudo build_dir=temp_results STEAMOS_TOOLS_BETA_HOOK="true" DIST="brewmaster" pbuilder --execute build-libretro-rustation-debuild.sh
