#!/bin/sh

test "$CRON" = "1" && cron -f -L 15 &
