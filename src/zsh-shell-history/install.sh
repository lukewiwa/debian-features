#!/usr/bin/env bash

set -eux

# Debug logging
echo "Starting zsh-shell-history installation script..."
echo "REMOTE_USER: $_REMOTE_USER"
echo "HISTFILE_DIRECTORY: $HISTFILE_DIRECTORY"
echo "REMOTE_USER_HOME: $_REMOTE_USER_HOME"

# Ensure the HISTFILE_DIRECTORY exists
mkdir -p "$HISTFILE_DIRECTORY"

# Ensure the _REMOTE_USER has permissions to read the volume directory
chown -R "$_REMOTE_USER" "$HISTFILE_DIRECTORY"
chmod -R u+r "$HISTFILE_DIRECTORY"

echo "Updated permissions for HISTFILE_DIRECTORY."

cat >> "$_REMOTE_USER_HOME/.zshrc" <<'EOF'

# persistent history options for devcontainer
export HISTFILE="${HISTFILE_DIRECTORY}/.zsh_history"
setopt APPEND_HISTORY         # don't overwrite the history file on exit
setopt INC_APPEND_HISTORY     # write each command immediately
setopt SHARE_HISTORY          # merge history across sessions
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
EOF

echo "Appended persistent history options to .zshrc."
