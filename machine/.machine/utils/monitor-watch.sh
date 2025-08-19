#!/usr/bin/env sh
set -eu

LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP-1}"

is_external_connected() {
  xrandr | awk -v lap="$LAPTOP_OUTPUT" '/ connected/ && $1 != lap {print; exit 0} END{exit 1}'
}

# Debounce state to avoid spamming xrandr on flaps
LAST_STATE="unknown"

while :; do
  if is_external_connected; then
    if [ "$LAST_STATE" != "ext" ]; then
      echo "[monitor-watch] External present."
      LAST_STATE="ext"
      # Do nothing: your current layout (including --externals-only) remains
    fi
  else
    if [ "$LAST_STATE" != "noext" ]; then
      echo "[monitor-watch] No external detected — restoring laptop-only."
      LAST_STATE="noext"
      # Bring laptop back alone, default wallpaper
      xrandr --output "$LAPTOP_OUTPUT" --auto --scale 1x1 --rotate normal --panning 0x0
      # Turn others off
      for out in $(xrandr | awk '/ connected| disconnected/ {print $1}'); do
        [ "$out" = "$LAPTOP_OUTPUT" ] || xrandr --output "$out" --off
      done
    fi
  fi
  sleep 3
done
