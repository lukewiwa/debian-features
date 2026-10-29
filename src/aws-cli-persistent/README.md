
# AWS CLI (persistent login) (aws-cli-persistent)

Installs the AWS CLI and keeps ~/.aws (profiles, credentials and SSO/login caches) in a per-project volume, so you stay logged in across rebuilds without sharing the host's credentials.

## Example Usage

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/aws-cli-persistent:1": {}
}
```



## How it works

- Installs the AWS CLI using the official
  `ghcr.io/devcontainers/features/aws-cli` feature, then moves `~/.aws` into a
  per-project volume.
- `~/.aws` is a symlink to `/usr/local/share/aws-config`. The whole directory
  is linked, not just the config and credentials files. The SSO token cache
  (`sso/cache`), the `aws login` cache (`login/cache`) and the assumed-role
  cache (`cli/cache`) always live under `~/.aws`, and no environment variable
  moves them.

## Per-project configuration

The AWS CLI's profiles, credentials and login caches live in a named volume,
`aws-cli-config-${devcontainerId}`. There is one volume per dev container, and
nothing is shared with the host or with other projects.

- Log in once per project, with whichever method you use: `aws login`,
  `aws configure sso` then `aws sso login`, or `aws configure` for access keys.
  For browser logins, use `--use-device-code` (SSO) or `--remote` (`aws login`)
  if the browser callback can't reach the container.
- The volume survives container rebuilds. Profiles and access keys persist
  indefinitely. SSO and `aws login` sessions persist until they expire, which
  your organisation's session duration controls; after that, run the login
  command again.
- To log a project out and clear its config, remove its volume. Find it with
  `docker volume ls --filter name=aws-cli-config-`, then delete it with
  `docker volume rm aws-cli-config-<id>`.

Tools that use the AWS SDKs (Terraform, CDK, boto3 and so on) read the same
`~/.aws`, so they share the login.

## Implementation details

- The directory is created at build time, owned by the remote user, and Docker
  seeds a new named volume from it. On Linux hosts, the dev container CLI then
  changes the remote user's UID to match the host. To handle this, the feature's
  entrypoint re-chowns the volume at start if its owner no longer matches.
- The re-chown needs the container to start as root, or the remote user to have
  passwordless `sudo`. The `mcr.microsoft.com/devcontainers/*` images meet both
  requirements.
- If the image already has a real `~/.aws` directory, it's moved to
  `~/.aws.backup` at build time.

## Troubleshooting

- **Permission denied writing to `/usr/local/share/aws-config`**: the
  entrypoint couldn't re-chown the volume. Look for a
  `aws-cli-persistent: cannot chown` line in the container logs. Then start
  the container as root or give the remote user passwordless `sudo`.
- **Only the remote user's login persists**: the symlink is in the remote
  user's home. Other users, including root in a non-root container, have their
  own `~/.aws`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lukewiwa/debian-features/blob/main/src/aws-cli-persistent/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
