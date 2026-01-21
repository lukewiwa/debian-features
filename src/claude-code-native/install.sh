#!/usr/bin/env bash

set -e

CLAUDE_VERSION="${VERSION:-latest}"

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

# Ensure /usr/local/share/claude-config exists and has correct permissions
if [ ! -d "/usr/local/share/claude-config" ]; then
    mkdir -p /usr/local/share/claude-config
    chmod 755 /usr/local/share/claude-config
else
    chmod 755 /usr/local/share/claude-config
fi

# Set up Claude configuration from mounted volumes BEFORE installation
echo "Setting up Claude configuration..."

CLAUDE_DIR="${_REMOTE_USER_HOME}/.claude"
CLAUDE_JSON="${_REMOTE_USER_HOME}/.claude.json"

echo "Ensuring parent directory for Claude configuration exists..."
su -l "$_REMOTE_USER" -c "mkdir -p $(dirname "$CLAUDE_DIR")"

if [ -L "$CLAUDE_DIR" ]; then
    echo "Removing existing symlink at $CLAUDE_DIR..."
    rm "$CLAUDE_DIR"
elif [ -e "$CLAUDE_DIR" ]; then
    echo "$CLAUDE_DIR exists and is not a symlink. Backing up to ${CLAUDE_DIR}.backup..."
    mv "$CLAUDE_DIR" "${CLAUDE_DIR}.backup"
fi
echo "Creating symlink for Claude configuration directory..."
ln -s /usr/local/share/claude-config/.claude "$CLAUDE_DIR"
chown -h "$_REMOTE_USER:$_REMOTE_USER" "$CLAUDE_DIR"

if [ -f "/usr/local/share/claude-config/claude.json" ]; then
    if [ -L "$CLAUDE_JSON" ]; then
        echo "Removing existing symlink at $CLAUDE_JSON..."
        rm "$CLAUDE_JSON"
    elif [ -e "$CLAUDE_JSON" ]; then
        echo "$CLAUDE_JSON exists and is not a symlink. Backing up to ${CLAUDE_JSON}.backup..."
        mv "$CLAUDE_JSON" "${CLAUDE_JSON}.backup"
    fi
    echo "Creating symlink for Claude configuration JSON file..."
    ln -s /usr/local/share/claude-config/claude.json "$CLAUDE_JSON"
    chown -h "$_REMOTE_USER:$_REMOTE_USER" "$CLAUDE_JSON"
fi
echo "Claude configuration setup complete."

echo "Claude Code ${CLAUDE_VERSION} installation complete!"
