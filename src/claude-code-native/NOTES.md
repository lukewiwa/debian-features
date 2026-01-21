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
