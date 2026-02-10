#!/usr/bin/env bash

set -eux

architecture="$(uname -m)"
case $architecture in
    i386) architecture="32bit";;
    x86_64) architecture="64bit";;
    aarch64 | armv8* | arm64) architecture="arm64";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_$architecture/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
dpkg -i "/tmp/session-manager-plugin.deb"

rm "/tmp/session-manager-plugin.deb"
