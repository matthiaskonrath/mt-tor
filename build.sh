#!/bin/bash


########################################################################
### CONFIG ###
########################################################################
### arm / arm64
docker_build_arch=arm



########################################################################
### BUILD + EXPORT ###
########################################################################
docker buildx build  --no-cache --platform linux/$docker_build_arch --output=type=docker -t mt-tor-$docker_build_arch .
docker save mt-tor-$docker_build_arch > mt-tor-$docker_build_arch.tar

