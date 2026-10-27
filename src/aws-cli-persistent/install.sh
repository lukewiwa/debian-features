#!/usr/bin/env bash

set -e

CONFIG_DIR="/usr/local/share/aws-config"

if [ -z "$_REMOTE_USER_HOME" ]; then
    _REMOTE_USER_HOME="$(su - "$_REMOTE_USER" -c 'echo "$HOME"')"
fi

# The per-project volume is mounted here at runtime. A new named volume is
# seeded from the image's directory, ownership included.
echo "Setting up per-project AWS CLI configuration directory..."
mkdir -p "$CONFIG_DIR"
chown "$_REMOTE_USER:" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Build-time ownership is not enough on its own: on Linux hosts the dev
# container CLI rewrites the remote user's UID to match the host after features
# install, and only re-chowns the home directory. Fix ownership at start.
ENTRYPOINT="/usr/local/share/aws-cli-persistent/entrypoint.sh"
mkdir -p "$(dirname "$ENTRYPOINT")"
cat > "$ENTRYPOINT" <<EOF
#!/bin/sh
dir="$CONFIG_DIR"
user="$_REMOTE_USER"
EOF
cat >> "$ENTRYPOINT" <<'EOF'
if [ "$(stat -c %u "$dir")" != "$(id -u "$user")" ]; then
    if [ "$(id -u)" = 0 ]; then
        chown -R "$user:" "$dir"
    else
        sudo -n chown -R "$user:" "$dir" 2>/dev/null \
            || echo "aws-cli-persistent: cannot chown $dir to $user (no root or sudo)" >&2
    fi
fi
exec "$@"
EOF
chmod 755 "$ENTRYPOINT"

# AWS_CONFIG_FILE and AWS_SHARED_CREDENTIALS_FILE only move two files; the SSO,
# 'aws login' and assumed-role caches always live under ~/.aws. Link the whole
# directory to the volume so all of it persists.
AWS_DIR="${_REMOTE_USER_HOME}/.aws"
if [ -L "$AWS_DIR" ]; then
    rm "$AWS_DIR"
elif [ -e "$AWS_DIR" ]; then
    echo "$AWS_DIR exists and is not a symlink. Backing up to ${AWS_DIR}.backup..."
    mv "$AWS_DIR" "${AWS_DIR}.backup"
fi
ln -s "$CONFIG_DIR" "$AWS_DIR"
chown -h "$_REMOTE_USER:" "$AWS_DIR"

echo "AWS CLI persistent login setup complete!"
