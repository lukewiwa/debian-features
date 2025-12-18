#!/usr/bin/env bash

set -eux

cat >> "$_CONTAINER_USER_HOME/.zshrc" <<'EOF'

# persistent history options for devcontainer
export HISTFILE="${HISTFILE_DIRECTORY}/.zsh_history"
setopt APPEND_HISTORY         # don't overwrite the history file on exit
setopt INC_APPEND_HISTORY     # write each command immediately
setopt SHARE_HISTORY          # merge history across sessions
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
EOF
