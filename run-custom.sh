#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)
# Host docker group GID
DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP | cut -d: -f3)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  MOUNTS+=" --mount type=bind,source=/etc/timezone,target=/etc/timezone,readonly"
  MOUNTS+=" --mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly"
}

prepare_docker_user_and_group() {
  # On run, if you specify USER_ID or GROUP_ID environment variables the system change internal user UID and group GID to that provided.
  # This also changes file ownership for those under /home/$USER/ owned by build-time UID and GUID.
  ENV_VARS+=" --env=USER_ID=$USER_ID"
  ENV_VARS+=" --env=GROUP_ID=$GROUP_ID"
}

prepare_docker_in_docker() {
  # Allow host docker access
  MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock"
  MOUNTS+=" --mount type=bind,source=$(which docker),target=/usr/local/bin/docker"
  # On run, if you specify DOCKER_GROUP_ID environment variable the system change internal docker group GID to that provided.
  ENV_VARS+=" --env=DOCKER_GROUP_ID=$DOCKER_GROUP_ID"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_in_docker

docker run --rm -it \
  --name "ubuntu-tini-user" \
  ${MOUNTS} \
  ${ENV_VARS} \
  rubensa/ubuntu-tini-user