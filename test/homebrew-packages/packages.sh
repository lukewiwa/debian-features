#!/bin/bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "brew is on PATH" brew --version
check "comma-separated packages are installed" bash -c 'brew list --formula | grep -qx jq && brew list --formula | grep -qx hello'
check "installed binaries run" hello --version
check "homebrew-core is not cloned" bash -c '[ ! -e "$(brew --repository)/Library/Taps/homebrew/homebrew-core" ]'
check "brew is on PATH in login shells" bash -lc 'brew --version'
check "brew update works cleanly" bash -c 'out=$(brew update 2>&1) && ! grep -qi error <<<"$out"'
check "brew is on a release" bash -c 'git -C "$(brew --repository)" describe --tags --exact-match'

reportResults
