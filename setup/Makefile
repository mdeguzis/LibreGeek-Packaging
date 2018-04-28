# Simple Makefile for a clean build environment
# Uses Arch Linux for latest and greatest build tools

IMAGE_NAME ?= arch-flatpak-dev
CONTAINER_NAME ?= flatpak-dev-01

all: build

build:
	sudo docker build \
		--tag $(IMAGE_NAME) \
		.

uninstall:
	sudo docker stop $(CONTAINER_NAME)
	sudo docker rm -f $(CONTAINRE_NAME)
	sudo docker rmi $(IMAGE_NAME)

run:
	sudo docker run $(CONTAINER_NAME) \
		--detach=true \
		--tty=true \
		--mount /home/mikeyd:/home/root, rw \
		--mount /mnt/server_media_y/libregee-packaging:/libregeek-packaging, rw \

stop:
	sudo docker stop $(CONTAINER_NAME)
