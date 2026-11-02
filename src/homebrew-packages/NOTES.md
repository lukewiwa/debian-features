## How it works

- Depends on `ghcr.io/meaningful-ooo/devcontainer-features/homebrew:2`, which
  installs Homebrew in `/home/linuxbrew/.linuxbrew` and puts it on `PATH`.
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
