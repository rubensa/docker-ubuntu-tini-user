#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
