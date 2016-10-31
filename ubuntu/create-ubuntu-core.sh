#!/bin/bash

# Very simple operation:
# See: https://hub.docker.com/r/ioft/i386-ubuntu_core/

VERSION=xenial
ARCH=i386

curl http://cdimage.ubuntu.com/ubuntu-base/releases/${VERSION}/release/ubuntu-base-${VERSION}-core-${ARCH}.tar.gz |\
gunzip | sudo docker import - professorkaos64/ubuntu-core:${VERSION}
