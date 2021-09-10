# Set base image
FROM debian:bullseye-slim

# Set container label
LABEL org.opencontainers.image.title="ioBroker Docker Image" \
      org.opencontainers.image.description="Docker image for ioBroker smarthome software" \
      org.opencontainers.image.documentation="https://github.com/dontobi/ioBroker.docker#readme" \
      org.opencontainers.image.authors="Tobias S. <github@myhome.zone>" \
      org.opencontainers.image.url="https://github.com/dontobi/ioBroker.docker" \
      org.opencontainers.image.source="https://github.com/dontobi/ioBroker.docker" \
      org.opencontainers.image.base.name="docker.io/library/debian:bullseye-slim" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${DATI}"

ENV DEBIAN_FRONTEND noninteractive

# Installation process
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \

        # ioBroker prerequisites
        acl apt-utils build-essential ca-certificates cifs-utils curl git gnupg2 gosu jq libcap2-bin \
        libcurl4-openssl-dev libgdcm3.0 libpam0g-dev libudev-dev locales lsb-release make \
        net-tools nfs-common pkg-config procps python3 python3-dev sudo unzip tar tzdata \
        udev wget \

        # Canvas prerequisites
        libcairo2-dev libjpeg-dev libgif-dev libpango1.0-dev libpixman-1-dev  librsvg2-dev \

    # Install node.js
    && curl -sL https://deb.nodesource.com/setup_${NODEJS}.x | bash \
    && apt-get update && apt-get install -y nodejs \

    # Install node-gyp - Node.js native addon build tool
    && npm install -g node-gyp \

    # Generate locales en_US.UTF-8 and de_DE.UTF-8
    && sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \

    # Install ioBroker
    && npm config set unsafe-perm true \
    && curl -sL https://iobroker.net/install.sh | sed -e 's/cap_net_admin,//' | bash - \
    && mkdir -p /opt/scripts/.docker_config/ \
    && echo $(hostname) > /opt/scripts/.docker_config/.install_host \
    && echo "starting" > /opt/scripts/.docker_config/.healthcheck \
    && echo $(hostname) > /opt/.firstrun \
    && npm config set unsafe-perm false \

    # Setting up iobroker-user
    && chsh -s /bin/bash iobroker \
    && usermod --home /opt/iobroker iobroker \
    && usermod -u 1000 iobroker \
    && groupmod -g 1000 iobroker \
    && chown root:iobroker /usr/sbin/gosu \
    && chmod +s /usr/sbin/gosu \

    # Clean up installation cache
    && apt-get autoclean -y \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /root/.cache/* /root/.npm/* \
    && rm -rf /var/lib/apt/lists/*

# Create directorys and copy scripts
COPY scripts /opt/scripts
COPY userscripts /opt/userscripts
RUN chmod 777 /opt/scripts/ \
    && chmod 777 /opt/userscripts/ \
    && chmod +x /opt/scripts/iobroker_startup.sh \
    && chmod +x /opt/scripts/setup_avahi.sh \
    && chmod +x /opt/scripts/setup_packages.sh \
    && chmod +x /opt/scripts/setup_zwave.sh \
    && chmod +x /opt/scripts/healthcheck.sh \
    && chmod +x /opt/scripts/maintenance.sh

# Backup initial ioBroker and userscript folder
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker \
    && tar -cf /opt/initial_userscripts.tar /opt/userscripts

# Change work dir
WORKDIR /opt/iobroker/

# Setting up ENVs
ENV DEBIAN_FRONTEND="teletype" \
    LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    SETGID=1000 \
    SETUID=1000 \
    TZ="Europe/Berlin"

# Expose default admin ui port
EXPOSE 8081

# Volume for ioBroker data
VOLUME [ "/opt/iobroker" ]

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --retries=5 \
    CMD ["/bin/bash", "-c", "/opt/scripts/healthcheck.sh"]

# Run startup-script
ENTRYPOINT ["/bin/bash", "-c", "/opt/scripts/iobroker_startup.sh"]
