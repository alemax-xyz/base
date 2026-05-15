[ "$CRON" != "1" ] && return

set -- crond -f
[ -n "$CRON_LOG_LEVEL" ] && set -- "$@" -l "$CRON_LOG_LEVEL"
[ -n "$CRON_LOG_FILE" ] && set -- "$@" -L "$CRON_LOG_FILE"
[ -n "$CRON_DIR" ] && set -- "$@" -c "$CRON_DIR"

suexec "$@" &
