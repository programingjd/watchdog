#!/usr/bin/env bash

# defaults to my_service is none is specified
SERVICE=${1:-"my_service"}
echo $SERVICE

WATCHDOG_FILE="${HOME}/watchdog-$SERVICE"
touch $WATCHDOG_FILE

(
  flock -x -w 3 200 || exit 1
  while true; do
    /etc/init.d/$SERVICE status  || /etc/init.d/$SERVICE start
    sleep 3
  done
) 200>$WATCHDOG_FILE
