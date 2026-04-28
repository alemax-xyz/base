fail() { echo "$1" 1>&2; exit $2; }
getuser() { getent passwd "$1" 2>/dev/null | cut -d: -f$2; }
getgroup() { getent group "$1" 2>/dev/null | cut -d: -f$2; }

[ -n "$PUID" -a "$PUID" -lt 0 ] 2>/dev/null && fail "Invalid PUID" 1
[ -n "$PGID" -a "$PGID" -lt 0 ] 2>/dev/null && fail "Invalid PGID" 2

[ -z "$PUID" -a -n "$PUSER" ] && PUID="$(getuser "$PUSER" 3)"
[ -z "$PGID" -a -n "$PGROUP" ] && PGID="$(getgroup "$PGROUP" 1)"

[ -z "$PUID" -a -n "$PGID" ] && PUID="$(getent passwd | awk -F: -v PGID="$PGID" '$4 == PGID {print $3}')"
[ -z "$PUID" ] && PUID="$(getuser 50 3)"
[ -z "$PUID" -a -n "$PGID" ] && PUID=$PGID
[ -z "$PUID" -a -n "$PUSER$PGROUP" ] && PUID=50
[ -z "$PUID" ] && PUID=0

PUID_NAME="$(getuser $PUID 1)"
if [ -z "$PUID_NAME" ]; then
	USER_NAME="$(getuser 50 1)"
	[ -z "$USER_NAME" ] && USER_NAME="$(getuser docker 1)"
	if [ -z "$USER_NAME" ]; then
		[ -z "$PUSER" ] && PUSER=docker
		[ -z "$PGID" ] && PGID=$PUID
		[ -z "$PGROUP" ] && PGROUP="$PUSER"
		groupadd --gid $PGID --system "$PGROUP" || exit 3
		useradd --no-create-home --system --uid $PUID --no-log-init --gid $PGID "$PUSER" || exit 4
	else
		PUSER="$USER_NAME"
		usermod --uid $PUID "$PUSER" || exit 5
	fi
elif [ -z "$PUSER" ]; then
	PUSER="$PUID_NAME"
elif [ "$PUID_NAME" != "$PUSER" ]; then
	[ "$PUID" = "0" -o "$PUSER" = "root" ] && fail "Invalid PUID/PUSER" 6
	usermod -l "$PUSER" "$PUID_NAME" || exit 7
fi

[ -z "$PGID" -a -n "$PUID" ] && PGID="$(getuser "$PUID" 4)"
[ -z "$PGID" -a -n "$PUSER" ] && PGID="$(getuser "$PUSER" 4)"
[ -z "$PGID" ] && PGID="$(getgroup 50 3)"
[ -z "$PGID" ] && PGID=$PUID

PGID_NAME="$(getgroup $PGID 1)"
if [ -z "$PGID_NAME" ]; then
	GROUP_NAME="$(getgroup 50 1)"
	[ -z "$GROUP_NAME" ] && GROUP_NAME="$(getgroup docker 1)"
	if [ -z "$GROUP_NAME" ]; then
		[ -z "$PGROUP" ] && PGROUP=docker
		groupadd --gid $PGID --system "$PGROUP" || exit 8
	else
		PGROUP="$GROUP_NAME"
		groupmod --gid $PGID "$PGROUP" || exit 9
	fi
elif [ -z "$PGROUP" ]; then
	PGROUP="$PGID_NAME"
elif [ "$PGID_NAME" != "$PGROUP" ]; then
	[ "$PGID" = "0" -o "$PGROUP" = "root" ] && fail "Invalid PGID/PGROUP" 10
	groupmod -n "$PGROUP" "$PGID_NAME" || exit 11
fi

[ "$(getuser "$PUID" 4)" = "$PGID" ] || usermod --gid $PGID "$PUSER" || exit 12

export PUID PGID PUSER PGROUP
