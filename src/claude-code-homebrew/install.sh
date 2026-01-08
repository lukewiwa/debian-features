#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-extra/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# temporary installation or use a temporary installation
ensure_nanolayer nanolayer_location "v0.5.6"

$nanolayer_location install devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/homebrew-package:1" \
    --option package='anthropics/claude-code/claude-code' --option version="$VERSION"

echo 'Done!'
