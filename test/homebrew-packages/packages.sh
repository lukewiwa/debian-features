#!/bin/bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "brew is on PATH" brew --version
check "comma-separated packages are installed" bash -c 'brew list --formula | grep -qx jq && brew list --formula | grep -qx hello'
check "installed binaries run" hello --version

reportResults
