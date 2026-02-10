# AWS Session Manager Plugin (Debian based)

Installs the AWS Session Manager plugin for Debian-based containers.

## Example Usage

```json
{
    "features": {
        "ghcr.io/devcontainers/features/aws-cli:1": {},
        "./aws-session-manager": {}
    }
}
```

## Notes

- This feature should be installed after the AWS CLI feature
- Supports x86_64, i386, and ARM64 architectures
- Designed for Debian-based distributions (Ubuntu, Debian, etc.)

## Usage with ECS

This plugin is commonly used to connect to running ECS containers via SSM. Example usage:

```bash
aws ssm start-session --profile <profile> \
    --target ecs:<cluster>_<task-id>_<task-id>-<container-id> \
    --document-name AWS-StartInteractiveCommand \
    --parameters '{"command":["bash"]}'
```
