#!/bin/bash
# Sample buider to use along side a PKGBUILD that will use an
# 	Arch Linux docker image
# Run makepkg -s within container
# Bind $PWD so results can be used
sudo docker run \
    --rm \
    --name archlinux-buider \
    --volume ${PWD}:${HOME} \
    arch-base \
    bash -c "cd ${HOME}; makepkg -s --noconfirm"

