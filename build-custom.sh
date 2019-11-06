#!/usr/bin/env bash

# Host docker group name
DOCKER_GROUP_NAME=docker
# Host docker group GID
DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP_NAME | cut -d: -f3)

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)
# Get current user name
USER_NAME=$(id -un)
# Get current user main group name
GROUP_NAME=$(id -gn)

prepare_docker_in_docker_support() {
  # To allow docker exucution the user needs to be memenber of docker group
  BUILD_ARGS+=" --build-arg DOCKER_IN_DOCKER_SUPPORT=true"
  BUILD_ARGS+=" --build-arg DOCKER_GROUP_NAME=$DOCKER_GROUP_NAME"
  BUILD_ARGS+=" --build-arg DOCKER_GROUP_ID=$DOCKER_GROUP_ID"
}

prepare_docker_user_and_group() {
  # On build, if you specify USER_NAME, USER_ID, GROUP_NAME or GROUP_ID those are used to define the
  # internal user and group created instead of default ones (user:1000 and group:1000)
  BUILD_ARGS+=" --build-arg USER_ID=$USER_ID"
  BUILD_ARGS+=" --build-arg GROUP_ID=$GROUP_ID"
  BUILD_ARGS+=" --build-arg USER_NAME=$USER_NAME"
  BUILD_ARGS+=" --build-arg GROUP_NAME=$GROUP_NAME"
}

prepare_docker_in_docker_support
prepare_docker_user_and_group

docker build --no-cache \
  -t "rubensa/ubuntu-tini-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .
