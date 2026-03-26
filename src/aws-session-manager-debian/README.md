
# AWS Session Manager (Debian based) (aws-session-manager-debian)

Install the AWS session manager plugin in the development container.

## Example Usage

```json
"features": {
    "ghcr.io/lukewiwa/debian-features/aws-session-manager-debian:0": {}
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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/lukewiwa/debian-features/blob/main/src/aws-session-manager-debian/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
