FROM pritunl/archlinux:latest

USER root

RUN pacman -Syy
RUN pacman -Syu

# Install some tools and software
RUN pacman -S flatpak

entrypoint /bin/bash
