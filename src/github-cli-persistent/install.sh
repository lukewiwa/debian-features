#!/usr/bin/env bash

set -e

CONFIG_DIR="/usr/local/share/gh-config"
GIT_CREDENTIAL_HELPER="${GITCREDENTIALHELPER:-true}"

if [ -z "$_REMOTE_USER_HOME" ]; then
    _REMOTE_USER_HOME="$(su - "$_REMOTE_USER" -c 'echo "$HOME"')"
fi

# The per-project volume is mounted here at runtime. A new named volume is
# seeded from the image's directory, ownership included.
echo "Setting up per-project GitHub CLI configuration directory..."
mkdir -p "$CONFIG_DIR"
chown "$_REMOTE_USER:" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Build-time ownership is not enough on its own: on Linux hosts the dev
# container CLI rewrites the remote user's UID to match the host after features
# install, and only re-chowns the home directory. Fix ownership at start.
ENTRYPOINT="/usr/local/share/github-cli-persistent/entrypoint.sh"
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
            || echo "github-cli-persistent: cannot chown $dir to $user (no root or sudo)" >&2
    fi
fi
exec "$@"
EOF
chmod 755 "$ENTRYPOINT"

# GH_CONFIG_DIR (set in containerEnv) points gh at the volume. Containers have
# no keyring, so gh stores the token in hosts.yml there. ~/.config/gh is linked
# to it for anything that expects the default path.
GH_DIR="${_REMOTE_USER_HOME}/.config/gh"
mkdir -p "$(dirname "$GH_DIR")"
chown "$_REMOTE_USER:" "$(dirname "$GH_DIR")"
if [ -L "$GH_DIR" ]; then
    rm "$GH_DIR"
elif [ -e "$GH_DIR" ]; then
    echo "$GH_DIR exists and is not a symlink. Backing up to ${GH_DIR}.backup..."
    mv "$GH_DIR" "${GH_DIR}.backup"
fi
ln -s "$CONFIG_DIR" "$GH_DIR"
chown -h "$_REMOTE_USER:" "$GH_DIR"

# 'gh auth setup-git' writes to ~/.gitconfig, which isn't on the volume and
# which VS Code may replace with the host's. Set it system-wide instead. When
# gh has no login it fails silently and git falls through to the next helper.
if [ "$GIT_CREDENTIAL_HELPER" = "true" ] && ! grep -qs "gh auth git-credential" /etc/gitconfig; then
    echo "Configuring git to use gh for GitHub credentials..."
    cat >> /etc/gitconfig <<'EOF'
[credential "https://github.com"]
	helper = !gh auth git-credential
[credential "https://gist.github.com"]
	helper = !gh auth git-credential
EOF
fi

echo "GitHub CLI persistent login setup complete!"
