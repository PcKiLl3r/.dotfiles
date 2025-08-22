#!/usr/bin/env sh
# =============================================================================
# preset3.sh
#
# This preset keeps your old layout intent (left/right externals, laptop on
# the right in your example) but now plays nicely with MST daisy chains:
#
# - By default we **prefer resolution**, so on a shared MST root the second
#   external will be set to 4K@30 to keep 4K on both (when needed).
# - If you want smoother cursor / gaming feel instead, pass --prefer-refresh
#   (or set env PREFER_REFRESH=1) and the secondary external will target
#   2560x1440@60 on the same root.
#
# Examples:
#   preset3.sh --mirror right --externals-only
#   preset3.sh --prefer-refresh
#   PREFER_REFRESH=1 preset3.sh
# =============================================================================
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Forward all flags; you can append --prefer-refresh / --prefer-rate here or at call site.
"$SCRIPT_DIR/monitors.sh" \
  --left  auto1:big \
  --middle auto2:big \
  --right eDP-1 \
  "$@"
