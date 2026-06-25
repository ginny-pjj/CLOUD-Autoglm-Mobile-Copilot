#!/bin/sh
set -eu

ADB_BIN="${ADB_PATH:-/usr/bin/adb}"
CONNECT_ADDR="${ADB_CONNECT_ADDRESS:-}"

if [ -n "$CONNECT_ADDR" ]; then
  echo "[entrypoint] Connecting ADB to ${CONNECT_ADDR} ..."
  "$ADB_BIN" start-server || true
  i=1
  while [ "$i" -le 5 ]; do
    "$ADB_BIN" connect "$CONNECT_ADDR" || true
    if "$ADB_BIN" devices | grep -q "${CONNECT_ADDR}[[:space:]]*device"; then
      echo "[entrypoint] ADB device connected: ${CONNECT_ADDR}"
      break
    fi
    echo "[entrypoint] ADB not ready, retry ${i}/5 ..."
    sleep 2
    i=$((i + 1))
  done
  "$ADB_BIN" devices -l || true
fi

exec "$@"
