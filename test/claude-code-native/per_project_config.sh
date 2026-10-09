#!/bin/bash

set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
check "claude-code is installed" claude --version
check "claude command is available" command -v claude
check "CLAUDE_CONFIG_DIR points at the volume" [ "$CLAUDE_CONFIG_DIR" = "/usr/local/share/claude-config" ]
check "config volume is mounted" grep -q " /usr/local/share/claude-config " /proc/self/mountinfo
check "config volume is writable by the remote user" bash -c 'touch "$CLAUDE_CONFIG_DIR/.write-test" && rm "$CLAUDE_CONFIG_DIR/.write-test"'
check "~/.claude links to the volume" [ "$(readlink "$HOME/.claude")" = "/usr/local/share/claude-config" ]

# Report results
reportResults
