#!/usr/bin/env bash

SCRIPT=$1
if [[ -x "$SCRIPT" ]]
then
    echo Script: '$SCRIPT' is not executable.
    exit 1
fi

FILENAME="${SCRIPT##*/}"

WATCHDOG_FILE="${HOME}/watchdog-${FILENAME}"
touch "${WATCHDOG_FILE}"

(
  flock -x -w 3 200 || exit 1
  while true; do
    "${SCRIPT}" status || "${SCRIPT}" start
    sleep 3
  done
) 200>"${WATCHDOG_FILE}"
