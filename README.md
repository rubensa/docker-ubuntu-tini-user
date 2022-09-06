# Docker image based on rubensa/ubuntu-tini with non root user support

This is a Docker image based on [rubensa/ubuntu-tini](https://github.com/rubensa/docker-ubuntu-tini) that allows you to connect and run with a non-root user created inside the image.

The internal user (user) has sudo and the image includes [fixuid](https://github.com/boxboat/fixuid) so you can set internal user (user) UID and internal group (group) GID to your current UID and GID by providing that info means of "--user" docker running option.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-user"
DOCKER_IMAGE_TAG="latest"

docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .

docker buildx build --load \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  .
```

You can also add build image args to change default non-root user (user:1000) and group (group:1000) like this:

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-user"
DOCKER_IMAGE_TAG="latest"

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
```

But this is generally not needed as the container can change user UID and group GID on run if "--user" option is provided (see bellow).

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-user"
DOCKER_IMAGE_TAG="latest"

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  ENV_VARS+=" --env=TZ=$(cat /etc/timezone)"
}

prepare_docker_user_and_group() {
  RUNNER+=" --user=${USER_ID}:${GROUP_ID}"
}

prepare_docker_from_docker() {
    MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker-host.sock"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_from_docker

docker run --rm -it \
  --name "${DOCKER_IMAGE_NAME}" \
  ${ENV_VARS} \
  ${MOUNTS} \
  ${RUNNER} \
  ${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} "$@"
```

*NOTE*: Mounting /var/run/docker.sock allows host docker usage inside the container (docker-from-docker).

This way, the internal user UID and group GID are changed to the current host user:group launching the container and the existing files under his internal HOME directory that where owned by user and group are also updated to belong to the new UID:GID.

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker exec -it \
  "${DOCKER_IMAGE_NAME}" \
  bash -l
```

This creates a bash shell run by the internal user.

## Stop

If you run the container without --rm you can stop it like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker start \
  "${DOCKER_IMAGE_NAME}"
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-user"

docker rm \
  "${DOCKER_IMAGE_NAME}"
```
