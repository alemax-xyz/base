#!/bin/sh

test -z "$PUID" && PUID=50 || test "$PUID" -eq "$PUID" || exit 2
PUSER=$(getent passwd $PUID 2>/dev/null | cut -d: -f1)
if [ -z "$PUSER" ]; then
	PUSER=$(getent passwd 50 2>/dev/null | cut -d: -f1)
	if [ -n "$PUSER" ]; then
		usermod --uid $PUID "$PUSER" || exit 2
	else
		PUID=0
		PUSER=root
	fi
fi
