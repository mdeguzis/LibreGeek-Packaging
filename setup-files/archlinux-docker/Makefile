# Makefile to run/build this Archlinux image
# This image is mainly for feeding PKGBUILDS too

VOLUME_DIR ?= $HOME
IMAGE_NAME = arch-base
COMMAND ?= echo COMMAND not supplied, e.g. COMMAND=\"ls -la /\" make run

all: build

build:
	@sudo docker build \
		--build-arg UID=$$(id -u) \
		--build-arg GID=$$(id -g) \
		--build-arg USERNAME=$$(whoami) \
		--file Dockerfile \
		--tag $(IMAGE_NAME) .
run:
	@# Ensure we feed in a volume to faciltate packaging
	@sudo docker run \
		--rm \
		--name arch-builder \
		$(IMAGE_NAME) \
		$(COMMAND)	

