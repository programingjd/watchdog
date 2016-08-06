#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo -e "Usage: ${0##*/} \e[32mcommand\e[0m"
  echo    "Runs a command and automatically restarts it if it crashes or exits."
  echo    "On SIGTKILL (kill -9), this script will stop, but the subprocess running the command is kept alive."
  echo    "On SIGTERM or SIGINT (kill, kill -15, kill -2), this script will stop and it will also stop the subprocess running the command (by send SIGTERM to the subprocess)."
  exit 1
fi

exec 200<$0

(
  flock -n --exclusive 200 && (
    setsid $0 $@ &
  ) && sleep 1
) && echo exit && exit

PGID=$(cat /proc/$$/stat)
PGID="${PGID##$$ * S $PPID }"
PGID="${PGID%% * 0}"

echo   "PID     PPID    PGID"
printf "%-8s%-8s%-8s\n"  $$ $PPID $PGID

COMMAND="$@"

stopped="no"

function trapped() {
  stopped="yes"
  trap - SIGINT
  kill -9 -$PGID
}

trap trapped SIGTERM SIGINT

while true; do
  echo -n "[$(date +'%Y%m%d-%H:%M:%S')] "
  echo "${COMMAND}"
  eval "${COMMAND}"
  echo "exited"
  if [ stopped == "yes" ]; then
   echo "stopped" 
   break
  fi
  sleep 1
done
