# Claude Code Native Installation Notes

## Configuration Mapping

This devcontainer feature automatically maps in any existing Claude Code configurations from your local machine into the container environment.

The following directories are mounted from your host machine:
- `~/.claude` - Main Claude Code configuration directory
- `~/.claude.json` - Main Claude Code configuration file

This allows you to:
- Preserve your Claude Code settings and preferences
- Maintain consistency between local and container environments
- Avoid reconfiguring Claude Code for each devcontainer

## Prerequisites - IMPORTANT

**Bind mounts require source paths to exist on the host machine before the container starts.**

This feature is designed to share your local Claude Code configuration with the container. You should have Claude Code installed and configured on your host machine first. When you install and run Claude Code locally, it automatically creates:
- `~/.claude/` - Configuration directory
- `~/.claude.json` - Configuration file

If you don't have Claude Code installed locally yet, install it first before using this devcontainer feature. This ensures your configuration is shared between your local environment and the container.

If you want to use this feature without a local Claude Code installation (not recommended), you can manually create empty placeholders:

```bash
mkdir -p ~/.claude
touch ~/.claude.json
```

However, without a local Claude Code installation, the mounted configuration will be empty and provide no benefit.

## Test Scenarios and CI Validation

The test scenarios use `initializeCommand` to ensure directories exist before container creation:

```json
"initializeCommand": "mkdir -p ${localEnv:HOME}${localEnv:USERPROFILE}/.claude && touch ${localEnv:HOME}${localEnv:USERPROFILE}/.claude.json"
```

This command:
- Runs on the HOST machine (not in container)
- Executes BEFORE the container is created
- Ensures bind mount sources exist for CI validation
- Works cross-platform (Linux/macOS via HOME, Windows via USERPROFILE)

## Implementation Details

### Bind Mounts
The feature uses bind mounts (not volumes) to directly map host directories:
- Host: `${localEnv:HOME}/.claude` → Container: `/usr/local/share/claude-config/.claude`
- Host: `${localEnv:HOME}/.claude.json` → Container: `/usr/local/share/claude-config/.claude.json`

### Symlinks
The install.sh script creates symlinks in the container user's home directory:
- `~/.claude` → `/usr/local/share/claude-config/.claude`
- `~/.claude.json` → `/usr/local/share/claude-config/.claude.json`

This ensures Claude Code reads the mounted configuration regardless of the container user.

## Troubleshooting

### Container fails to start with mount errors
This usually means Claude Code is not installed on your host machine, or hasn't been run yet to create its configuration files.

Verify the directories exist on your host:
```bash
ls -la ~/.claude
ls -la ~/.claude.json
```

**Recommended solution**: Install Claude Code on your host machine and run it at least once to create the configuration files.

**Alternative** (if you want to use this feature without local Claude Code): Create placeholder files manually:
```bash
mkdir -p ~/.claude
touch ~/.claude.json
```

Note: Without a local Claude Code installation, you won't benefit from shared configuration.

### Configuration not persisting between container rebuilds
Check that symlinks are correctly created:
```bash
# Inside container
ls -la ~/.claude
ls -la ~/.claude.json
```

Both should be symlinks pointing to `/usr/local/share/claude-config/`.
