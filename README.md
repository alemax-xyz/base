## Base image for other docker images

The image contains `passwd`, `sudo`, `cron` and [krallin/tini](https://github.com/krallin/tini).
It is built on top of the [clover/busybox](https://hub.docker.com/r/clover/busybox/).

### Enviroment variables

| Name | Default value | Description |
|---|---|---|
| `PUID` | `50` | Desired _UID_ of the process owner _*_ |
| `PGID` | primary group id of the _UID_ user (`50`) | Desired _GID_ of the process owner _*_ |
| `CRON` | _not set_ | Will start _cron_ inside the container if set to `1` |
