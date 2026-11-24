
# Homebrew packages (homebrew-packages)

Installs a list of Homebrew packages, like a Brewfile, in one feature. Installs Homebrew first, without cloning homebrew-core.

## Example Usage

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/homebrew-packages:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | Space- or comma-separated Homebrew formulae to install, e.g. 'bat git-delta fzf' | string | - |

## How it works

- Installs Homebrew in `/home/linuxbrew/.linuxbrew`, owned by the container's
  user, and puts it on `PATH` (login shells too). Only `Homebrew/brew` is
  cloned, shallow, at its latest release: formulae come from Homebrew's JSON
  API, so there is no homebrew-core clone (several GB). `brew update` still
  works.
- The prefix belongs to a `linuxbrew` group the user is in and is
  group-writable, so Homebrew keeps working on Linux hosts, where the dev
  container CLI changes the user's UID to match the host's after the build.
- Runs one `brew install` with every package in `packages`, as the user that
  owns the Homebrew prefix (Homebrew won't run as root).
- Packages are baked into the image, so rebuilds reuse the cached layer instead
  of reinstalling on every container create.

## Example

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/homebrew-packages:1": {
        "packages": "bat git-delta fzf glow jq just lazygit neovim"
    }
}
```

## Why not `homebrew-package`?

`ghcr.io/devcontainers-extra/features/homebrew-package` installs one package,
and a feature can only be listed once per dev container.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lukewiwa/debian-features/blob/main/src/homebrew-packages/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
