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

# The installer only puts claude in ~/.local/bin, which isn't on PATH for every
# shell, user or lifecycle command. Link rather than copy so auto-updates, which
# repoint ~/.local/bin/claude, carry through.
if [ -z "$_REMOTE_USER_HOME" ]; then
    _REMOTE_USER_HOME="$(su - "$_REMOTE_USER" -c 'echo "$HOME"')"
fi
ln -sf "${_REMOTE_USER_HOME}/.local/bin/claude" /usr/local/bin/claude

# The per-project volume is mounted here at runtime. A new named volume is
# seeded from the image's directory, ownership included.
echo "Setting up per-project Claude configuration directory..."
mkdir -p "$CONFIG_DIR"
chown "$_REMOTE_USER:" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Build-time ownership is not enough on its own: on Linux hosts the dev
# container CLI rewrites the remote user's UID to match the host after features
# install, and only re-chowns the home directory. Fix ownership at start.
ENTRYPOINT="/usr/local/share/claude-code-native/entrypoint.sh"
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
            || echo "claude-code-native: cannot chown $dir to $user (no root or sudo)" >&2
    fi
fi
exec "$@"
EOF
chmod 755 "$ENTRYPOINT"

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
