set /etc/init/*.sh && [ -e "$1" ] && for FILE; do . "$FILE"; done
wait
