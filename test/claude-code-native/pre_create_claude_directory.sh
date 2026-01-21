#!/bin/bash

set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
check "claude-code is installed" claude --version
check "claude command is available" command -v claude
check "claude config directory is mounted" [ -L "$HOME/.claude" ]

# Report results
reportResults
