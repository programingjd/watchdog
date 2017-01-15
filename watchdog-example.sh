#!/usr/bin/env bash

# Directory containing this script
DIR=$(dirname $(readlink /proc/$$/fd/255))
ARG="$1"
shift

################################################################################

NAME="Sleep watchdog"
COMMAND="sleep ${1:-infinity}"
LOG="${DIR}/sleep_watchdog.log"

################################################################################

WATCHDOG_COMMAND="${DIR}/watchdog.sh ${COMMAND}"
SHELL_EXE="$(type -P bash)"
SHELL_EXE="$(readlink -e "${SHELL_EXE}")"

# Find process
function findProcess() {
  PID=
    for PROC in /proc/*/; do
      EXE="$(type -P ${PROC}exe)"
      EXE="${EXE:-${PROC}exe}"
      EXE="$(readlink -e "${EXE}")"
      if [[ "${EXE}" == "${SHELL_EXE}" ]]; then
        CMD_LINE="$(cat "${PROC}cmdline" | tr "\0" " ")"
        if [[ "bash ${WATCHDOG_COMMAND} " == "${CMD_LINE}" ]]; then
          PROC=${PROC#/*/}
          PID=${PROC%/}
          break
        fi
      fi
    done
}
findProcess

function start() {
  if [[ -n  "${PID}" ]]; then
    echo -e "\e[32m${NAME}\e[0m is already running" >&2
    false
  else
    echo -n -e "Starting \e[32m${NAME}\e[0m..." >&2
    (${WATCHDOG_COMMAND} > "${LOG}" 2>&1)&
    echo "Done" >&2
    true
  fi
}

function stop() {
  if [[ -n "${PID}" ]]; then
    echo -n -e "Stopping \e[32m${NAME}\e[0m..." >&2
    $(kill -9 ${PID} > /dev/null 2>&1) && (echo "Done" && true) || (echo "Failed" && false)
  else
    echo -e "\e[32m${NAME}\e[0m is not running" >&2
    true
  fi
}

function restart() {
  stop && (findProcess; start)
}

function status() {
  if [[ -n "${PID}" ]]; then
    echo -e "\e[32m${NAME}\e[0m is running" >&2
    true
  else
    echo -e "\e[32m${NAME}\e[0m is not running" >&2
    false
  fi
}

case "${ARG}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status} [n]"
esac
