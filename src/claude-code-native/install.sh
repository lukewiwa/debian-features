#!/usr/bin/env bash

set -e

CLAUDE_VERSION="${VERSION:-latest}"
CONFIG_DIR="/usr/local/share/claude-config"

echo "Installing Claude Code ${CLAUDE_VERSION}..."

# Security best practice: download first, then execute
INSTALL_SCRIPT="/tmp/claude-install-${RANDOM}.sh"

echo "Downloading Claude Code installer..."
if ! curl -fsSL https://claude.ai/install.sh -o "$INSTALL_SCRIPT"; then
    echo "ERROR: Failed to download Claude Code installer"
    rm -f "$INSTALL_SCRIPT"
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"

echo "Running Claude Code installer..."
if ! su -l "$_REMOTE_USER" -c "bash $INSTALL_SCRIPT $CLAUDE_VERSION"; then
    echo "ERROR: Claude Code installation failed"
    rm -f "$INSTALL_SCRIPT"
    exit 1
fi

rm -f "$INSTALL_SCRIPT"

# The per-project volume is mounted here at runtime. A new named volume is
# seeded from the image's directory, ownership included, so creating it owned
# by the remote user here is what makes the volume writable without a chown
# at container start.
echo "Setting up per-project Claude configuration directory..."
mkdir -p "$CONFIG_DIR"
chown "$_REMOTE_USER:" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# CLAUDE_CONFIG_DIR (set in containerEnv) points Claude at the volume, and
# .claude.json lives inside it too, so there is no single-file mount to break.
# ~/.claude is linked to it for anything that expects the default path.
CLAUDE_DIR="${_REMOTE_USER_HOME}/.claude"
if [ -L "$CLAUDE_DIR" ]; then
    rm "$CLAUDE_DIR"
elif [ -e "$CLAUDE_DIR" ]; then
    echo "$CLAUDE_DIR exists and is not a symlink. Backing up to ${CLAUDE_DIR}.backup..."
    mv "$CLAUDE_DIR" "${CLAUDE_DIR}.backup"
fi
ln -s "$CONFIG_DIR" "$CLAUDE_DIR"
chown -h "$_REMOTE_USER:" "$CLAUDE_DIR"

echo "Claude Code ${CLAUDE_VERSION} installation complete!"
