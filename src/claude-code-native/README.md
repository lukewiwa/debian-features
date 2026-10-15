
# Claude Code (native installer) (claude-code-native)

Claude Code is an agentic coding tool that lives in your terminal. Installs via the official native installer and keeps its config and login in a per-project volume, isolated from the host.

## Example Usage

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/claude-code-native:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version to install: 'stable', 'latest', or a specific semantic version (e.g., '1.2.3') | string | latest |

## Customizations

### VS Code Extensions

- `anthropic.claude-code`

# Claude Code Native Installation Notes

## Per-project configuration

Claude Code's configuration, login and session history live in a named volume,
`claude-code-config-${devcontainerId}`, one per dev container. Nothing is shared
with the host or with other projects.

- Log in once per project with `claude` then `/login`. In a headless container
  Claude prints a URL: open it in your host browser and paste the code back.
- The volume survives container rebuilds, so you stay logged in.
- Removing the volume (`docker volume rm claude-code-config-<id>`) logs that
  project out and clears its config.

### Why not share the host's `~/.claude`?

Version 0.x bind-mounted the host's `~/.claude` and `~/.claude.json`. That gave
anything running in the container write access to host settings, including
hooks that execute on the host the next time Claude runs there, and exposed
every other project's transcripts and memory. Isolating the config is what makes
it reasonable to run Claude in the container with fewer permission prompts.

If you do want host config in a particular project, add the bind mount in that
project's `devcontainer.json` rather than in this feature.

## Implementation Details

- `CLAUDE_CONFIG_DIR=/usr/local/share/claude-config` is set in `containerEnv`.
  With it set, Claude keeps `.claude.json` inside that directory too, so there
  is no single-file mount (which breaks when a file is replaced by rename).
- `~/.claude` is a symlink to the same directory for tools that expect the
  default path.
- The directory is created owned by the remote user at build time, and Docker
  seeds a new named volume from it. On Linux hosts the dev container CLI then
  changes the remote user's UID to match the host, so an entrypoint re-chowns
  the volume at start if its owner no longer matches. That needs the container
  to start as root, or the container user to have passwordless `sudo`.

## Upgrading from 0.x

1.0.0 no longer mounts host config. Pin `:1` to opt in and log in again inside
the container. Placeholder files created for 0.x (`~/.claude.json` via
`initializeCommand`) are no longer needed.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lukewiwa/debian-features/blob/main/src/claude-code-native/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
