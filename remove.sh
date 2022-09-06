#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker rm \
  "${DOCKER_IMAGE_NAME}"
