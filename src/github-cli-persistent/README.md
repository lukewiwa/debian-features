
# GitHub CLI (persistent login) (github-cli-persistent)

Installs the GitHub CLI and keeps its config and login in a per-project volume, so you stay logged in across rebuilds without sharing the host's credentials.

## Example Usage

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/github-cli-persistent:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| gitCredentialHelper | Configure git (system-wide) to use gh for github.com credentials, like 'gh auth setup-git' | boolean | true |

## How it works

- Installs the GitHub CLI using the official
  `ghcr.io/devcontainers/features/github-cli` feature, then moves its config
  into a per-project volume.
- `GH_CONFIG_DIR=/usr/local/share/gh-config` is set in `containerEnv`, and
  `~/.config/gh` is a symlink to the same directory.
- Containers don't have a system keyring, so `gh auth login` falls back to
  storing the token in plain text in `hosts.yml` in that directory. That file
  is what keeps you logged in.

## Per-project configuration

gh's config and login live in a named volume,
`github-cli-config-${devcontainerId}`. There is one volume per dev container,
and nothing is shared with the host or with other projects.

- Log in once per project with `gh auth login`. Pick "Login with a web
  browser" and open the URL it prints on the host.
- The volume survives container rebuilds, so you stay logged in.
- To log a project out, run `gh auth logout` or remove its volume. Find it with
  `docker volume ls --filter name=github-cli-config-`, then delete it with
  `docker volume rm github-cli-config-<id>`.

To skip the login entirely, pass a token in from the host instead. gh prefers
`GH_TOKEN` over a stored login:

```json
"containerEnv": {
    "GH_TOKEN": "${localEnv:GH_TOKEN}"
}
```

## Git credentials

With `gitCredentialHelper` (the default), `/etc/gitconfig` gets the same
helper that `gh auth setup-git` would add, so `git push` over HTTPS to
github.com uses gh's login. It's set system-wide because `~/.gitconfig` isn't
on the volume and VS Code may replace it with the host's.

When gh isn't logged in, the helper fails silently and git falls through to
the next one, such as VS Code's forwarded credentials. Set
`"gitCredentialHelper": false` to leave git config alone.

## Implementation details

- The directory is created at build time, owned by the remote user, and Docker
  seeds a new named volume from it. On Linux hosts, the dev container CLI then
  changes the remote user's UID to match the host. To handle this, the feature's
  entrypoint re-chowns the volume at start if its owner no longer matches.
- The re-chown needs the container to start as root, or the remote user to have
  passwordless `sudo`. The `mcr.microsoft.com/devcontainers/*` images meet both
  requirements.

## Troubleshooting

- **Permission denied writing to `/usr/local/share/gh-config`**: the
  entrypoint couldn't re-chown the volume. Look for a
  `github-cli-persistent: cannot chown` line in the container logs. Then start
  the container as root or give the remote user passwordless `sudo`.
- **Logged in but `gh` acts as someone else**: `GH_TOKEN` or `GITHUB_TOKEN` in
  the environment takes priority over the stored login. Check
  `gh auth status`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lukewiwa/debian-features/blob/main/src/github-cli-persistent/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
