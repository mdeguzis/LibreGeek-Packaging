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
	sudo docker run \
		--name $(CONTAINER_NAME) \
		--tty=true \
		--volume /home/mikeyd:/home/root:rw \
		--volume /mnt/server_media_y/libregeek-packaging:/libregeek-packaging:rw \
		--volume /mnt/server_media_y/github_repos/libregeek-packaging/repo:/repo:rw \
		$(IMAGE_NAME)

stop:
	sudo docker stop $(CONTAINER_NAME)
