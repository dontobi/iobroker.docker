FROM balenalib/armv7hf-node:12-buster

MAINTAINER dontobi <github@myhome.zone>

# QEMU for ARM to build ARM image on X86 machine
RUN ["cross-build-start"]

# Install prerequisites (as listed in iobroker installer.sh)
RUN apt-get update && apt-get install -y --no-install-recommends \
    acl apt-utils build-essential git gnupg2 gosu lsb-release jq \
    libavahi-compat-libdnssd-dev libcap2-bin libcurl4-openssl-dev \
    libgdcm2-dev libpam0g-dev libudev-dev locales net-tools \
    pkg-config python3 python3-dev unzip wget

# Generating locales
RUN sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

# Create scripts directorys and copy scripts
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

# Install ioBroker and Setting up iobroker-user
WORKDIR /
RUN apt-get update \
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
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /root/.cache/* /root/.npm/* \
    && rm -rf /var/lib/apt/lists/* \
    && npm config set unsafe-perm false

# Backup initial ioBroker and userscript folder
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker \
    && tar -cf /opt/initial_userscripts.tar /opt/userscripts

# Setting up ENVs
ENV DEBIAN_FRONTEND="teletype" \
    LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    SETGID=1000 \
    SETUID=1000 \
    TZ="Europe/Berlin"

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --retries=5 \
    CMD ["/bin/bash", "-c", "/opt/scripts/healthcheck.sh"]

# QEMU for ARM to build ARM image on X86 machine
RUN ["cross-build-end"]

# Run startup-script
ENTRYPOINT ["/bin/bash", "-c", "/opt/scripts/iobroker_startup.sh"]
