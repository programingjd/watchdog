#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo -e "Usage: ${0##*/} \e[32mcommand\e[0m"
  echo    "Runs a command and automatically restarts it if it crashes or exits."
  echo    "On SIGTKILL (kill -9), this script will stop, but the subprocess running the command is kept alive."
  exit 1
fi

exec {FD}<$0

(
  flock -n --exclusive ${FD} && (
   setsid $0 $@ &
  ) && sleep 1
) && exit

PGID=$(cat /proc/$$/stat)
PGID="${PGID##$$ * S $PPID }"
PGID="${PGID%% * 0}"

echo   "PID     PPID    PGID"
printf "%-8s%-8s%-8s\n"  $$ $PPID $PGID

COMMAND="$@"

while true; do
  echo -n "[$(date +'%Y%m%d-%H:%M:%S')] "
  echo "${COMMAND}"
  eval "${COMMAND}"
  sleep 1
done
