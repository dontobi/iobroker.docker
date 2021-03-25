FROM balenalib/armv7hf-node:14-buster
MAINTAINER dontobi <github@myhome.zone>

# QEMU for ARM to build ARM image on X86 machine
RUN ["cross-build-start"]

# Building
COPY scripts /opt/scripts
COPY userscripts /opt/userscripts
WORKDIR /
RUN install_packages acl apt-utils build-essential curl git gnupg2 gosu \
    lsb-release jq libavahi-compat-libdnssd-dev libcairo2-dev libcap2-bin \
    libcurl4-openssl-dev libgdcm2-dev libgif-dev libjpeg-dev libpam0g-dev \
    libpango1.0-dev libpixman-1-dev librsvg2-dev libudev-dev locales make \
    net-tools pkg-config procps python python-dev sudo udev unzip wget \
    && sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && chmod 777 /opt/scripts/ \
    && chmod 777 /opt/userscripts/ \
    && chmod +x /opt/scripts/iobroker_startup.sh \
    && chmod +x /opt/scripts/setup_avahi.sh \
    && chmod +x /opt/scripts/setup_packages.sh \
    && chmod +x /opt/scripts/setup_zwave.sh \
    && chmod +x /opt/scripts/healthcheck.sh \
    && chmod +x /opt/scripts/maintenance.sh \
    && apt-get update \
    && npm config set unsafe-perm true \
    && curl -sL https://iobroker.net/install.sh | bash - \
    && mkdir -p /opt/scripts/.docker_config/ \
    && echo $(hostname) > /opt/scripts/.docker_config/.install_host \
    && echo "starting" > /opt/scripts/.docker_config/.healthcheck \
    && echo $(hostname) > /opt/.firstrun \
    && chsh -s /bin/bash iobroker \
    && usermod --home /opt/iobroker iobroker \
    && usermod -u 1000 iobroker \
    && groupmod -g 1000 iobroker \
    && apt-get autoclean -y \
    && apt-get autoremove --purge \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /root/.cache/* /root/.npm/* \
    && rm -rf /var/lib/apt/lists/* \
    && npm config set unsafe-perm false \
    && tar -cf /opt/initial_iobroker.tar /opt/iobroker \
    && tar -cf /opt/initial_userscripts.tar /opt/userscripts

# Setting up ENVs
ENV DEBIAN_FRONTEND="teletype" \
    LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    SETGID=1000 \
    SETUID=1000 \
    TZ="Europe/Berlin"

# Setting up Ports
EXPOSE 8081

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --retries=5 \
    CMD ["/bin/bash", "-c", "/opt/scripts/healthcheck.sh"]

# Run startup-script
ENTRYPOINT ["/bin/bash", "-c", "/opt/scripts/iobroker_startup.sh"]

# QEMU for ARM to build ARM image on X86 machine
RUN ["cross-build-end"]
