#!/bin/bash

echo "Checking avahi-daemon installation state..."

if [ -e /usr/sbin/avahi-daemon ] && [ -e /var/run/dbus ]
then
  echo "Avahi is already installed..."
else
  echo "Avahi-daemon is NOT installed. Going to install it now..."
  apt-get update > /opt/scripts/avahi_startup.log 2>&1
  sudo apt-get install -qq -y --no-install-recommends avahi-daemon avahi-utils libavahi-compat-libdnssd-dev libnss-mdns >> /opt/scripts/avahi_startup.log 2>&1
  rm -rf /var/lib/apt/lists/* >> /opt/scripts/avahi_startup.log 2>&1
  echo "Configuring avahi-daemon..."
  sed -i '/^rlimit-nproc/s/^\(.*\)/#\1/g' /etc/avahi/avahi-daemon.conf
  echo "Configuring dbus..."
  mkdir /var/run/dbus/
fi

if [ -f /var/run/dbus/pid ];
then
  rm -f /var/run/dbus/pid
fi

if [ -f /var/run/avahi-daemon//pid ];
then
  rm -f /var/run/avahi-daemon//pid
fi

echo "Starting dbus..."
dbus-daemon --system

echo "Starting avahi-daemon..."
/etc/init.d/avahi-daemon start

exit 0
