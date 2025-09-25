#!/usr/bin/env bash
set -euo pipefail

LAYOUT_A="real-prog-dvo-k"
LAYOUT_B="real-prog-dvorak"
SECONDARY="us"
VARIANT=",,"
OPTIONS="ctrl:nocaps,grp:alt_shift_toggle"

current="$(hyprctl -j devices | jq -r '.keyboards[0].layout')"
target="$LAYOUT_A"
[ "$current" = "$LAYOUT_A" ] && target="$LAYOUT_B"

hyprctl keyword input:kb_layout  "${target},${SECONDARY}"
hyprctl keyword input:kb_variant "${VARIANT}"
hyprctl keyword input:kb_options "${OPTIONS}"
