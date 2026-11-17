#!/usr/bin/env bash
# Usage: tool/locked.sh <command...>
# Serialises heavy Flutter commands (test/analyze) across parallel agents so
# they don't fight over build/native_assets/sqlite3.dll. Waits up to ~20 min.
export PATH=/c/flutter/bin:$PATH
cd "$(dirname "$0")/.." || exit 1
LOCK=.tool_lock
for i in $(seq 1 600); do
  if mkdir "$LOCK" 2>/dev/null; then
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
    "$@"
    exit $?
  fi
  # break stale lock older than 15 minutes
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +15 2>/dev/null)" ]; then rmdir "$LOCK" 2>/dev/null; fi
  sleep 2
done
echo "locked.sh: timed out waiting for lock" >&2; exit 1
