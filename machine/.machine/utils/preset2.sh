#!/usr/bin/env sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
"$SCRIPT_DIR/monitors.sh" \
  --left  auto1:big:vertical \
  --middle auto2:big \
  --right eDP-1
