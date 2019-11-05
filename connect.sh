#!/usr/bin/env bash

IMAGE_BUILD_USER_NAME=user

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-user \
  bash -l
