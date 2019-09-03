#!/bin/bash

ARG=$1

if [[ $ARG == "--build" ]]; then
	docker build -t centos7-builder .

elif [[ $ARG == "--run" ]]; then
	docker run \
		--rm \
		--interactive \
		--tty \
        --name centos7-builder1 \
		--volume $PWD:/home/builder \
		centos7-builder
else
	cat<<-EOF
	Invalid option: $ARG
	Options: 
	    --build
	    --run
	EOF
	exit 1
fi
