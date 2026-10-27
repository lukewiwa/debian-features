#!/bin/bash

set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
check "aws is installed" aws --version
check "config volume is mounted" grep -q " /usr/local/share/aws-config " /proc/self/mountinfo
check "config volume is writable by the remote user" bash -c 'touch /usr/local/share/aws-config/.write-test && rm /usr/local/share/aws-config/.write-test'
check "~/.aws links to the volume" [ "$(readlink "$HOME/.aws")" = "/usr/local/share/aws-config" ]
check "aws configure writes to the volume" bash -c '
    trap "rm -f /usr/local/share/aws-config/config" EXIT
    aws configure set region ap-southeast-2 --profile feature-test
    grep -q "feature-test" /usr/local/share/aws-config/config
    [ "$(aws configure get region --profile feature-test)" = "ap-southeast-2" ]'

# Report results
reportResults
