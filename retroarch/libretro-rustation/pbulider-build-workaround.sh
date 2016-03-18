#!/bin/bash

# There are issues updating the cargo index using pdebuild.
# See: https://github.com/rust-lang/cargo/issues/2492

# Login to the chroot and do build there
pkgname="libretro-rustation"
export build_dir="${HOME}/build-${pkgname}-temp"
mkdir -p $build_dir

sudo -E build_dir=$build_dir STEAMOS_TOOLS_BETA_HOOK="true" DIST="brewmaster" pbuilder --execute build-libretro-rustation-debuild.sh
