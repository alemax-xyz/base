## Base image for other docker images

The image contains [passwd](https://packages.ubuntu.com/focal/passwd), [sudo](https://packages.ubuntu.com/focal/sudo),
 [cron](https://packages.ubuntu.com/focal/cron) and [krallin/tini](https://github.com/krallin/tini) and is built on top
 of [clover/busybox](https://hub.docker.com/r/clover/busybox/).

### Enviroment variables
| Name | Default value | Description |
|---|---|---|
| `PUID` | `50` | Desired _UID_ of the process owner _*_ |
| `PGID` | primary group id of the _UID_ user (`50`) | Desired _GID_ of the process owner _*_ |
| `CRON` | _not set_ | Will start _cron_ inside the container if set to `1` |
