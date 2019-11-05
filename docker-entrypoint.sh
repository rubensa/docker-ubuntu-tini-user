#!/bin/bash
set -Eeuo pipefail

# Fix image build time user UID and group GID
OLD_USER_ID=$(getent passwd $USER | cut -d: -f3)
OLD_GROUP_ID=$(getent group $GROUP | cut -d: -f3)

if [ "$USER_ID" != "$OLD_USER_ID" ]; then
  usermod -u $USER_ID $USER
  find /home/$USER/ -user $OLD_USER_ID -exec chown -h $USER_ID {} \;
  echo "Changed USER_ID from $OLD_USER_ID to $USER_ID"
else
  echo "USER_ID $USER_ID not changed"
fi

if [ "$GROUP_ID" != "$OLD_GROUP_ID" ]; then
  groupmod -g $GROUP_ID $GROUP
  find /home/$USER/ -group $OLD_GROUP_ID -exec chgrp -h $GROUP_ID {} \;

  usermod -g $GROUP_ID $USER
  echo "Changed GROUP_ID from $OLD_GROUP_ID to $GROUP_ID"
else
  echo "GROUP_ID $GROUP_ID not changed"
fi

if [ "$DOCKER_IN_DOCKER_SUPPORT" = "true" ] ; then
  # Fix image build time docker group GID
  OLD_DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP | cut -d: -f3)

  if [ "$DOCKER_GROUP_ID" != "$OLD_DOCKER_GROUP_ID" ]; then
    groupmod -g $DOCKER_GROUP_ID $DOCKER_GROUP

    echo "Changed DOCKER_GROUP_ID from $OLD_DOCKER_GROUP_ID to $DOCKER_GROUP_ID"
  else
    echo "SDOCKER_GROUP_ID $DOCKER_GROUP_ID not changed"
  fi
fi

# all commands will be dropped to the correct user
exec gosu $USER "$@"