#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "zsh history directory exists" [ -d /opt/features/zsh-shell-history ]

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
