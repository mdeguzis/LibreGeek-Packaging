FROM pritunl/archlinux:latest

USER root

RUN pacman -Syy
RUN pacman -Syu

# Install some tools and software
# Use --asdeps for any default providers since this is a minimal image
RUN pacman -S --asdeps --noconfirm base-devel flatpak

entrypoint /bin/bash
