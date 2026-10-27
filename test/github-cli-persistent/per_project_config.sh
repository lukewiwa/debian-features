#!/bin/bash

set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
check "gh is installed" gh --version
check "GH_CONFIG_DIR points at the volume" [ "$GH_CONFIG_DIR" = "/usr/local/share/gh-config" ]
check "config volume is mounted" grep -q " /usr/local/share/gh-config " /proc/self/mountinfo
check "config volume is writable by the remote user" bash -c 'touch "$GH_CONFIG_DIR/.write-test" && rm "$GH_CONFIG_DIR/.write-test"'
check "~/.config/gh links to the volume" [ "$(readlink "$HOME/.config/gh")" = "/usr/local/share/gh-config" ]
check "gh reads its login from the volume" bash -c '
    printf "github.com:\n    oauth_token: gho_testtoken\n    user: test\n    git_protocol: https\n" > "$GH_CONFIG_DIR/hosts.yml"
    trap "rm -f \"$GH_CONFIG_DIR/hosts.yml\"" EXIT
    [ "$(GH_TOKEN= GITHUB_TOKEN= gh auth token)" = "gho_testtoken" ]'
check "git uses gh for github.com credentials" bash -c 'git config --system --get-all credential.https://github.com.helper | grep -q "gh auth git-credential"'

# Report results
reportResults
