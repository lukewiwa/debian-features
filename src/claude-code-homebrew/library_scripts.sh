#!/bin/bash


clean_download() {
    # The purpose of this function is to download a file with minimal impact on container layer size
    # this means if no downloader is available (curl or wget), a temporary one will be downloaded
    # but without remaining in the layer once the script is done, therefore requiring as root
    DEST=$1
    URL=$2
    DOWNLOADER=
    if [ -x "$(command -v curl)" ]; then
        DOWNLOADER="curl"
    elif [ -x "$(command -v wget)" ]; then
        DOWNLOADER="wget"
    fi

    if [ "$DOWNLOADER" = "" ]; then
        apt-get update
        apt-get install -y --no-install-recommends wget
        DOWNLOADER="wget"
        CLEAN_WGET="true"
    fi

    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$URL" -o "$DEST"
    elif [ "$DOWNLOADER" = "wget" ]; then
        wget -q "$URL" -O "$DEST"
    fi

    if [ "$CLEAN_WGET" = "true" ]; then
        apt-get remove -y wget
        apt-get autoremove -y
        rm -rf /var/lib/apt/lists/*
    fi
}

ensure_nanolayer() {
    # Ensures nanolayer is available either via existing binary or temporary download
    # Argument 1: variable name to store the path to the nanolayer binary
    # Argument 2: nanolayer version to use (e.g., "v0.5.6")

    local __result_var=$1
    local version=$2

    # Check if nanolayer is already installed
    if [ -x "$(command -v nanolayer)" ]; then
        eval "$__result_var='nanolayer'"
        return
    fi

    # Check if NANOLAYER_LOCATION is set and valid
    if [ -n "${NANOLAYER_LOCATION:-}" ] && [ -x "$NANOLAYER_LOCATION" ]; then
        eval "$__result_var='$NANOLAYER_LOCATION'"
        return
    fi

    # Download nanolayer temporarily
    local nanolayer_path="/tmp/nanolayer-$$"

    # Determine architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac

    # Determine libc type (gnu or musl)
    local libc="gnu"
    if [ -f /etc/alpine-release ] || ldd --version 2>&1 | grep -q musl; then
        libc="musl"
    fi

    local download_url="https://github.com/devcontainers-extra/nanolayer/releases/download/${version}/nanolayer-${arch}-unknown-linux-${libc}"

    clean_download "$nanolayer_path" "$download_url"
    chmod +x "$nanolayer_path"

    # Set up cleanup trap
    trap 'rm -f "$nanolayer_path"' EXIT

    eval "$__result_var='$nanolayer_path'"
}
