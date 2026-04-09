#!/bin/sh

test -z "$PGID" && PGID=$(id -g "$PUSER") || test "$PGID" -eq "$PGID" || exit 2
PGROUP=$(getent group $PGID 2>/dev/null | cut -d: -f1)
if [ -z "$PGROUP" ]; then
	PGROUP=$(id -gn "$PUSER")
	groupmod --gid $PGID "$PGROUP" || exit 2
else
	test $(id -g "$PUSER") -eq $PGID || usermod --gid $PGID "$PUSER" || exit 2
fi
