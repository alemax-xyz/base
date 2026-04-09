#!/bin/sh

set /etc/init/*.sh && test -e "$1" && for FILE; do . "$FILE"; done
