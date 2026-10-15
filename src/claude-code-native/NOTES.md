## How it works

- Installs Claude Code with Anthropic's native installer (`https://claude.ai/install.sh`),
  run as the remote user. No Node.js is needed. The binary lands in
  `~/.local/bin/claude`, and `/usr/local/bin/claude` links to it so `claude` is
  on `PATH` for every shell and lifecycle command.
- The `version` option is passed straight to the installer: `latest`, `stable`,
  or an exact version such as `2.1.58`. Claude Code auto-updates itself after
  install. To keep a pinned version, also set `"DISABLE_AUTOUPDATER": "1"` in
  your `containerEnv`.
- The `anthropic.claude-code` VS Code extension is added automatically.

## Per-project configuration

Claude Code's configuration, login and session history live in a named volume,
`claude-code-config-${devcontainerId}`. There is one volume per dev container,
and nothing is shared with the host or with other projects.

- Log in once per project: run `claude` and follow the prompt. If the browser
  callback can't reach the container, copy the code shown in the browser and
  paste it into the terminal.
- The volume survives container rebuilds, so you stay logged in.
- To log a project out and clear its config, remove its volume. Find it with
  `docker volume ls --filter name=claude-code-config-`, then delete it with
  `docker volume rm claude-code-config-<id>`.

To skip the browser login, for example in Codespaces or CI, pass a token in
from the host instead:

```json
"containerEnv": {
    "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}"
}
```

Generate the token on the host with `claude setup-token`. `ANTHROPIC_API_KEY`
works the same way.

### Why not share the host's `~/.claude`?

Version 0.x bind-mounted the host's `~/.claude` and `~/.claude.json`. That had
two problems:

- Anything running in the container could write to the host's settings,
  including hooks that run on the host the next time Claude starts there.
- Every other project's transcripts and memory were visible inside the
  container.

Keeping the config isolated is what makes it reasonable to run Claude in the
container with fewer permission prompts.

If you want host config in a particular project, add the bind mounts to that
project's `devcontainer.json` instead of relying on this feature:

```json
"mounts": [
    "source=${localEnv:HOME}/.claude,target=/usr/local/share/claude-config,type=bind"
]
```

This shares settings, hooks, skills and history. It doesn't share the host
login: macOS keeps credentials in the Keychain, and the host's `~/.claude.json`
lives outside `~/.claude`. Expect to log in once anyway. Before doing this, read
the two problems listed above.

## Implementation details

- `CLAUDE_CONFIG_DIR=/usr/local/share/claude-config` is set in `containerEnv`.
  With it set, Claude keeps `.claude.json` inside that directory too. That
  avoids mounting a single file, which breaks when the file is replaced by a
  rename.
- `~/.claude` is a symlink to the same directory, for tools that expect the
  default path.
- The directory is created at build time, owned by the remote user, and Docker
  seeds a new named volume from it. On Linux hosts, the dev container CLI then
  changes the remote user's UID to match the host. To handle this, the feature's
  entrypoint re-chowns the volume at start if its owner no longer matches.
- The re-chown needs the container to start as root, or the remote user to have
  passwordless `sudo`. The `mcr.microsoft.com/devcontainers/*` images meet both
  requirements.

## Troubleshooting

- **`claude: command not found` or permission denied for another user**:
  `/usr/local/bin/claude` links into the remote user's home directory. Users
  who can't read that home directory can't run it. Run Claude as the remote
  user.
- **Permission denied writing to `/usr/local/share/claude-config`**: the
  entrypoint couldn't re-chown the volume. Look for a
  `claude-code-native: cannot chown` line in the container logs. Then start
  the container as root or give the remote user passwordless `sudo`.

## Upgrading from 0.x

1.0.0 no longer mounts host config. To upgrade, change the feature reference
to `:1` and log in again inside the container. The placeholder files that 0.x
needed (such as `~/.claude.json` created via `initializeCommand`) can be
removed.
