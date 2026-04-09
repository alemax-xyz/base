#!/bin/sh

test "$CRON" = "1" && cron -f -l -L 15 &
