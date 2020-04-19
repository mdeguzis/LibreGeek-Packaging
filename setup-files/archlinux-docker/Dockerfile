FROM archlinux/base

USER root

# Fed from Makefile
ARG USERNAME=nobody
ARG UID=0
ARG GID=0

RUN echo $USERNAME \
    && echo $UID \
    && echo $GID

# Create user (makepkg cannot run as root)
RUN groupadd -g $GID -o $USERNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USERNAME

# Update
RUN pacman -Syu --noconfirm

# Software for buildig
RUN pacman -S --noconfirm base-devel 

# Drop to user
USER $USERNAME

# Set bash as default
#ENTRYPOINT /bin/bash $@
