FROM rubensa/ubuntu-tini
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Define non-root user and group id's
ARG USER_ID=1000
ARG GROUP_ID=1000

# Define non-root user and group names
ARG USER_NAME=user
ARG GROUP_NAME=group

# Expose non-root user and group names
ENV USER_NAME=$USER_NAME
ENV GROUP_NAME=$GROUP_NAME

# fixuid version to install
ARG FIXUID_VERSION=0.5

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Basic apt configuration
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Install locales, ca-certificates, curl, sudo
    && apt-get install -y --no-install-recommends locales ca-certificates curl sudo 2>&1 \
    #
    # Configure locale
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    #
    # Create a non-root user with custom group
    && addgroup --gid ${GROUP_ID} ${GROUP_NAME} \
    && adduser --uid ${USER_ID} --ingroup ${GROUP_NAME} --home /home/${USER_NAME} --shell /bin/bash --disabled-password --gecos "User" ${USER_NAME} \
    #
    # Create some user directories
    && mkdir -p /home/${USER_NAME}/.config \
    && mkdir -p /home/${USER_NAME}/.local/bin \
    && chown -R ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME} \
    #
    # Set default non-root user umask to 002 to give group all file permissions (interactive non-login shell)
    # Allow override by setting UMASK_SET environment variable
    && printf "\nUMASK_SET=\${UMASK_SET:-002}\numask \"\$UMASK_SET\"\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Add sudo support for non-root user
    && echo "${USER_NAME} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    #
    # Add fixuid
    && curl -sSL https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz | tar -C /sbin -xzf - \
    && chown root:root /sbin/fixuid \
    && chmod 4755 /sbin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: ${USER_NAME}\ngroup: ${GROUP_NAME}\npaths:\n  - /home/${USER_NAME}" > /etc/fixuid/config.yml \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME

# Set default working directory to user home directory
WORKDIR ${HOME}

# Set the default shell to bash rather than sh
ENV SHELL=/bin/bash

# Configure locale
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

# Allways execute tini and fixuid
ENTRYPOINT [ "/sbin/tini", "--", "/sbin/fixuid" ]

# By default execute an interactive shell (executes ~/.bashrc)
CMD [ "/bin/bash", "-i" ]
