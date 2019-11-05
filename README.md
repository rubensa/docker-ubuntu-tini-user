# Docker image based on rubensa/ubuntu-tini with non root user support

This is a Docker image based on [rubensa/ubuntu-tini](https://github.com/rubensa/docker-ubuntu-tini) that allows you to connect and run with a non-root user created inside de image.

The internal user (user) has sudo and the image includes machinery so you can set internal user (user) UID and internal group (group) GID to your current UID and GID by providing that info means of USER_ID and GROUP_ID environmental variables on running.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
```

If you want to add Docker in Docker support you "must" enably that by setting build ARG "DOCKER_IN_DOCKER_SUPPORT=true" and need to specify a DOCKER_GROUP_ID matching your host docker GID

```
#!/usr/bin/env bash

# Host docker group name
DOCKER_GROUP=docker
# Host docker group GID
DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP | cut -d: -f3)

prepare_docker_in_docker_support() {
  # To allow docker exucution the user needs to be memenber of docker group
  BUILD_ARGS+=" --build-arg DOCKER_IN_DOCKER_SUPPORT=true"
  BUILD_ARGS+=" --build-arg DOCKER_GROUP=$DOCKER_GROUP"
  BUILD_ARGS+=" --build-arg DOCKER_GROUP_ID=$DOCKER_GROUP_ID"
}

prepare_docker_in_docker_support

docker build --no-cache \
  -t "rubensa/ubuntu-tini-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .
```

You can also add build image args to change default non-root user (user:1000) and group (group:1000) like this:

```
#!/usr/bin/env bash

# Host docker group name
DOCKER_GROUP=docker
# Host docker group GID
DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP | cut -d: -f3)

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
  BUILD_ARGS+=" --build-arg DOCKER_GROUP=$DOCKER_GROUP"
  BUILD_ARGS+=" --build-arg DOCKER_GROUP_ID=$DOCKER_GROUP_ID"
}

prepare_docker_user_and_group() {
  # On build, if you specify USER_NAME, USER_ID, GROUP_NAME or GROUP_ID those are used to define the
  # internal user and group created instead of default ones (user:1000 and group:1000)
  BUILD_ARGS+=" --build-arg USER_ID=$USER_ID"
  BUILD_ARGS+=" --build-arg GROUP_ID=$GROUP_ID"
  BUILD_ARGS+=" --build-arg USER=$USER_NAME"
  BUILD_ARGS+=" --build-arg GROUP=$GROUP_NAME"
}

prepare_docker_in_docker_support
prepare_docker_user_and_group

docker build --no-cache \
  -t "rubensa/ubuntu-tini-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .
```

But this is generally not needed as the container can change user ID and group ID on run if "-u" option is provided (see bellow).

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)

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

prepare_docker_timezone
prepare_docker_user_and_group

docker run --rm -it \
  --name "ubuntu-tini-user" \
  ${MOUNTS} \
  ${ENV_VARS} \
  rubensa/ubuntu-tini-user
```

*NOTE*: Mounting /etc/timezone and /etc/localtime allows you to use your host timezone on container.

Specifying USER_ID, and GROUP_ID environment variables on run, makes the system change internal user UID and group GID to that provided.  This also changes files under his home directory that are owned by user and group to those provided.

This allows to set default owner of the files to you (very usefull for mounted volumes).

If you enabled Docker in Docker support and you are memmber of docker group in your host system you can run de container like:

```
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
```

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

IMAGE_BUILD_USER_NAME=user

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-user \
  bash -l
```

This creates a bash shell run by the specified user (that must exist in the container - by default "user" if not specified other on container build)

*NOTE*:  Keep in mind that if you do not specify user, the command is run as root in the container.

If you added docker build image args to change default non-root user you sould connect to the running container like this:

```
#!/usr/bin/env bash

# Get current user name
IMAGE_BUILD_USER_NAME=$(id -un)

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-user \
  bash -l
```
## Stop

You can stop the running container like this:

```
#!/usr/bin/env bash

docker stop \
  ubuntu-tini-user
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

docker start \
  ubuntu-tini-user
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

docker rm \
  ubuntu-tini-user
```
