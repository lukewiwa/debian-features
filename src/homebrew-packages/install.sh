#!/usr/bin/env bash

set -e

PACKAGES="$(echo "${PACKAGES:-}" | tr ',' ' ')"
BREW="/home/linuxbrew/.linuxbrew/bin/brew"

if [ -z "${PACKAGES// /}" ]; then
    echo "No Homebrew packages requested, nothing to do"
    exit 0
fi

# Homebrew refuses to run as root, so install as the owner of the Homebrew
# prefix (the homebrew feature sets that up).
BREW_USER="$(stat -c %U "$(dirname "$(dirname "$BREW")")")"
if [ "$BREW_USER" = "root" ]; then
    echo "Homebrew prefix is owned by root; Homebrew can't install as root" >&2
    exit 1
fi

echo "Installing Homebrew packages as ${BREW_USER}: ${PACKAGES}"
# shellcheck disable=SC2086
su "$BREW_USER" -c "HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_CLEANUP=1 $BREW install $PACKAGES"

# Keep the image layer small: downloads and caches aren't needed after install
su "$BREW_USER" -c "$BREW cleanup --prune=all -s" || true
rm -rf "/home/${BREW_USER}/.cache/Homebrew" 2>/dev/null || true

echo "Homebrew packages installed!"
