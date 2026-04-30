#!/bin/sh

[ -e /etc/profile ] || (set -- /etc/entrypoint/*.sh && [ -e "$1" ] && for FILE; do . "${FILE}"; done; export -p > /etc/profile) || exit $?
[ -e /etc/profile ] || exit 127
. /etc/profile
exec "$@"
