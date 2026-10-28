# Debian based dev container features

## Releasing

Features are published by pushing a `v*` tag that points at a commit on `main`:

```bash
git switch main && git pull
git tag v2026.10.29
git push origin v2026.10.29
```

The release workflow validates every feature and runs the tests first; if any of them fail, nothing is published. Only features whose `version` in `devcontainer-feature.json` has been bumped get a new release, and a PR with the regenerated documentation is opened afterwards.
