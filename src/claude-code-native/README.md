# Claude Code (Native Installer)

Installs Claude Code using the official native installer and automatically mounts your local Claude configuration into the dev container.

## Prerequisites

**Important**: Before using this feature, ensure the following directories exist on your local machine:

```bash
mkdir -p ~/.claude
touch ~/.claude.json
```

These directories will be bind-mounted into the container, allowing you to:
- Preserve your Claude Code settings and preferences across container rebuilds
- Maintain consistency between local and container environments
- Avoid reconfiguring Claude Code for each dev container

## Usage

Add this feature to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/lukewiwa/debian-features/claude-code-native:latest": {}
    }
}
```

### Version Options

You can specify which version to install:

```json
{
    "features": {
        "ghcr.io/lukewiwa/debian-features/claude-code-native:latest": {
            "version": "stable"
        }
    }
}
```

Available options:
- `"latest"` (default) - Latest development version
- `"stable"` - Latest stable release
- Specific semantic version (e.g., `"1.2.3"`)

## How It Works

1. Downloads and runs the official Claude Code installer
2. Bind-mounts `~/.claude` and `~/.claude.json` from your host machine to the container
3. Creates symlinks in the container user's home directory to the mounted configuration
4. Ensures proper permissions for the remote user

## Configuration Mapping

The following are mounted from your host machine:

| Host Path | Container Path | Type |
|-----------|---------------|------|
| `~/.claude` | `/usr/local/share/claude-config/.claude` | bind mount |
| `~/.claude.json` | `/usr/local/share/claude-config/.claude.json` | bind mount |

Inside the container, symlinks are created:
- `~/.claude` → `/usr/local/share/claude-config/.claude`
- `~/.claude.json` → `/usr/local/share/claude-config/.claude.json`

## Troubleshooting

### Container fails to start with mount errors

If you see errors about mount failures, ensure that `~/.claude` directory and `~/.claude.json` file exist on your host machine before starting the container:

```bash
mkdir -p ~/.claude
touch ~/.claude.json
```

### Configuration not persisting

Verify that the bind mounts are working correctly:

```bash
# Inside the container
ls -la ~/.claude
ls -la ~/.claude.json
```

Both should be symlinks pointing to `/usr/local/share/claude-config/`.
