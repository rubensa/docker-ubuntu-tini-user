#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-user"
DOCKER_IMAGE_TAG="20.04"

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)
# Get current user name
USER_NAME=$(id -un)
# Get current user main group name
GROUP_NAME=$(id -gn)

prepare_docker_user_and_group() {
  # On build, if you specify USER_NAME, USER_ID, GROUP_NAME or GROUP_ID those are used to define the
  # internal user and group created instead of default ones (user:1000 and group:1000)
  BUILD_ARGS+=" --build-arg USER_ID=$USER_ID"
  BUILD_ARGS+=" --build-arg GROUP_ID=$GROUP_ID"
  BUILD_ARGS+=" --build-arg USER_NAME=$USER_NAME"
  BUILD_ARGS+=" --build-arg GROUP_NAME=$GROUP_NAME"
}

prepare_docker_user_and_group

docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .

docker buildx build --load \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  .
