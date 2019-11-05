FROM rubensa/ubuntu-tini
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Define non-root user and group id's
ARG USER_ID=1000
ARG GROUP_ID=1000

# Define non-root user and group names
ARG USER=user
ARG GROUP=group

# Expose non-root user and group id's
ENV USER_ID=$USER_ID
ENV GROUP_ID=$GROUP_ID

# Expose non-root user and group names
ENV USER=$USER
ENV GROUP=$GROUP

# Docker in Docker support
ARG DOCKER_IN_DOCKER_SUPPORT
ARG DOCKER_GROUP_ID=1001
ARG DOCKER_GROUP=docker
ENV DOCKER_IN_DOCKER_SUPPORT=${DOCKER_IN_DOCKER_SUPPORT}
ENV DOCKER_GROUP_ID=${DOCKER_GROUP_ID}
ENV DOCKER_GROUP=${DOCKER_GROUP}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Basic apt configuration
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Install ca-certificates, curl, sudo, gosu
    && apt-get install -y --no-install-recommends ca-certificates curl sudo gosu 2>&1 \
    #
    # Create a non-root user with custom group
    && addgroup --gid ${GROUP_ID} ${GROUP} \
    && adduser --uid ${USER_ID} --ingroup ${GROUP} --home /home/${USER} --shell /bin/bash --disabled-password --gecos "User" ${USER} \
    #
    # Create some user directories
    && mkdir -p /home/${USER}/.config \
    && mkdir -p /home/${USER}/.local/bin \
    && chown ${USER}:${GROUP} /home/${USER}/.config \
    && chown ${USER}:${GROUP} /home/${USER}/.local \
    && chown ${USER}:${GROUP} /home/${USER}/.local/bin \
    #
    # Set default non-root user umask to 002 to give group all file permissions
    # Allow override by setting UMASK_SET environment variable
    && printf "\nUMASK_SET=\${UMASK_SET:-002}\numask \"\$UMASK_SET\"\n" >> /home/${USER}/.bashrc \
    #
    # Add sudo support for non-root user
    && echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER} \
    #
    # Docker in Docker support
    && if [ "$DOCKER_IN_DOCKER_SUPPORT" = "true" ] ; \
      then addgroup --gid ${DOCKER_GROUP_ID} ${DOCKER_GROUP}; usermod -a -G ${DOCKER_GROUP} ${USER}; \
    fi \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Execute the init command
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "/sbin/tini", "--", "docker-entrypoint.sh" ]

CMD [ "/bin/bash" ]
