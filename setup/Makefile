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
	@sudo docker stop $(CONTAINER_NAME)
	@sudo docker rm -f $(CONTAINRE_NAME)
	@sudo docker rmi $(IMAGE_NAME)

run:
	@# check for run state, if any errors true will not be set, so throw away errors
	@if [ `sudo docker ps -qf name="$(CONTAINER_NAME)"` ]; then \
		echo "Container already running"; \
	else \
		echo "Starting container"; \
		sudo docker rm -f $(CONTAINER_NAME); \
		sudo docker run \
			--detach=true \
			--tty=true \
			--name $(CONTAINER_NAME) \
			--volume /home/mikeyd:/home/root:rw \
			--volume /mnt/server_media_y/libregeek-packaging:/libregeek-packaging:rw \
			--volume /mnt/server_media_y/github_repos/libregeek-packaging/repo:/repo:rw \
			$(IMAGE_NAME); \
		exit 0; \
	fi

clean: stop
	@sudo docker rm -f $(CONTAINER_NAME)
	
stop:
	@sudo docker stop $(CONTAINER_NAME)
