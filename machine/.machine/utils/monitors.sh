#!/usr/bin/env sh

set -eu

WALLPAPER_DIR="$HOME/.machine/images/backgrounds"
DEFAULT_WALLPAPER="bg2.jpg"
SEXY_WALLPAPER="bg.png"

# === USER TUNABLES ===========================================================
LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP-1}"
LAPTOP_MODE="${LAPTOP_MODE:-1920x1200}"
LAPTOP_SCALE="${LAPTOP_SCALE:-1.5}"   # your original default
DEFAULT_EXT_SCALE="${DEFAULT_EXT_SCALE:-1.75}" # non-4K external default
BIG_EXT_SCALE="${BIG_EXT_SCALE:-1.0}"          # 4K "big" scaling
# ============================================================================

# -------- util: preferred mode for an output --------------------------------
preferred_mode() {
  # First non-blank mode line after "<OUTPUT> connected"
  xrandr | awk -v out="$1" '
    $0 ~ "^"out" connected" { s=1; next }
    s==1 && $0 ~ /^[[:space:]]+[0-9]/ { print $1; exit }
  '
}

# -------- util: list connected externals (not laptop) -----------------------
connected_externals() {
  xrandr | awk -v lap="$LAPTOP_OUTPUT" '
    / connected/ && $1 != lap { print $1 }
  '
}

# -------- wallpaper logic (kept from your script, generalized to N heads) ---
set_wallpaper() {
  local img="$1"
  echo "Setting wallpaper: $WALLPAPER_DIR/$img"
  pkill -x nitrogen >/dev/null 2>&1 || true
  nohup nitrogen --restore >/dev/null 2>&1 &

  # Try to apply to multiple heads (0..4). Nitrogen maps heads by index.
  # We stop on first failure to avoid noisy logs.
  for head in 0 1 2 3 4; do
    nohup nitrogen --set-zoom-fill "$WALLPAPER_DIR/$img" --head="$head" >/dev/null 2>&1 || break
    sleep 0.3
  done
}

# -------- parse a "NAME[:big][:vertical]" token into env vars ---------------
# Out vars (by prefix): <PFX>_OUT, <PFX>_BIG, <PFX>_VERT
parse_spec() {
  # $1 = position prefix (LEFT|MIDDLE|RIGHT), $2 = spec token
  local pfx="$1"; local tok="${2:-}"
  [ -z "$tok" ] && return 0

  # defaults
  eval "${pfx}_BIG=0"
  eval "${pfx}_VERT=0"

  IFS=':' read -r name flag1 flag2 <<EOF
$tok
EOF

  # Flags can come in any two orders or be omitted
  for f in "$flag1" "$flag2"; do
    case "${f:-}" in
      big) eval "${pfx}_BIG=1" ;;
      vertical|portrait) eval "${pfx}_VERT=1" ;;
      "" ) : ;;
      *)
        # If it's not a known flag, it might actually be part of name that had colons — ignore
        :
        ;;
    esac
  done

  eval "${pfx}_OUT=\$name"
}

# -------- choose autos for auto1/auto2 --------------------------------------
resolve_auto_outputs() {
  # Build an array of externals
  EXTS="$(connected_externals || true)"
  AUTO1="$(printf "%s\n" $EXTS | sed -n '1p' || true)"
  AUTO2="$(printf "%s\n" $EXTS | sed -n '2p' || true)"

  for PFX in LEFT MIDDLE RIGHT; do
    eval CUR=\$${PFX}_OUT
    case "${CUR:-}" in
      auto1) eval "${PFX}_OUT=\$AUTO1" ;;
      auto2) eval "${PFX}_OUT=\$AUTO2" ;;
    esac
  done
}

# -------- scale chooser for externals ---------------------------------------
ext_scale_for() {
  # arg1: isBig (0/1)
  if [ "${1:-0}" = "1" ]; then
    printf "%s" "$BIG_EXT_SCALE"
  else
    printf "%s" "$DEFAULT_EXT_SCALE"
  fi
}

# -------- main monitor config ------------------------------------------------
configure_monitors() {
  local img="$1"

  # Enable parsing defaults: middle defaults to laptop if not supplied
  LEFT_OUT=""; RIGHT_OUT=""; MIDDLE_OUT=""
  LEFT_BIG=0; RIGHT_BIG=0; MIDDLE_BIG=0
  LEFT_VERT=0; RIGHT_VERT=0; MIDDLE_VERT=0

  # Gather args
  # Allowed forms:
  #   --left  NAME[:big][:vertical]
  #   --middle NAME[:big][:vertical]
  #   --right NAME[:big][:vertical]
  #   NAME can be actual output (HDMI-1, DP-1, ...) or auto1/auto2
  while [ $# -gt 0 ]; do
    case "$1" in
      --left)   parse_spec LEFT   "${2:-}"; shift 2;;
      --middle) parse_spec MIDDLE "${2:-}"; shift 2;;
      --right)  parse_spec RIGHT  "${2:-}"; shift 2;;
      --big|--sexy) # already handled earlier in arg parse
        shift
        ;;
      -*)
        # ignore unknown flags here; earlier parse may have consumed them
        shift
        ;;
      *)
        # positional (likely wallpaper), skip
        shift
        ;;
    esac
  done

  # Default middle to laptop if not specified
  if [ -z "${MIDDLE_OUT:-}" ]; then
    MIDDLE_OUT="$LAPTOP_OUTPUT"
  fi

  # Replace autos
  resolve_auto_outputs

  # Validate and normalize: ensure outputs are non-empty if set,
  # and gather the set of "used" outputs.
  USED_OUTPUTS=""
  add_used() { USED_OUTPUTS="$USED_OUTPUTS $1"; }

  for item in LEFT MIDDLE RIGHT; do
    eval OUT=\$${item}_OUT
    if [ -n "${OUT:-}" ]; then
      add_used "$OUT"
    fi
  done

  # If middle is laptop, we'll use laptop defaults
  # Otherwise if laptop is not placed anywhere, we’ll still keep it enabled in middle
  if ! printf "%s\n" $USED_OUTPUTS | grep -q "^$LAPTOP_OUTPUT$"; then
    # ensure laptop is present as middle if not specified anywhere else
    if [ -z "${MIDDLE_OUT:-}" ] || [ "$MIDDLE_OUT" != "$LAPTOP_OUTPUT" ]; then
      MIDDLE_OUT="$LAPTOP_OUTPUT"
      add_used "$LAPTOP_OUTPUT"
    fi
  fi

  # Build initial xrandr command to turn ON used outputs with mode/scale/rotate,
  # and turn OFF all other known outputs found by xrandr.
  XR="xrandr"
  ALL_OUTS="$(xrandr | awk '/ connected| disconnected/ { print $1 }')"

  for OUT in $ALL_OUTS; do
    if printf "%s\n" $USED_OUTPUTS | grep -q "^$OUT$"; then
      # ----- determine role & flags (fix: correct [ ] spacing + use elif chain) -----
      ROLE=""; BIG=0; VERT=0
      if   [ "$OUT" = "${LEFT_OUT:-}"   ]; then ROLE="LEFT";   BIG=$LEFT_BIG;   VERT=$LEFT_VERT
      elif [ "$OUT" = "${MIDDLE_OUT:-}" ]; then ROLE="MIDDLE"; BIG=$MIDDLE_BIG; VERT=$MIDDLE_VERT
      elif [ "$OUT" = "${RIGHT_OUT:-}"  ]; then ROLE="RIGHT";  BIG=$RIGHT_BIG;  VERT=$RIGHT_VERT
      fi

      MODE="$(preferred_mode "$OUT")"
      [ -z "$MODE" ] && MODE="auto"

      ROT="normal"
      [ "${VERT:-0}" = "1" ] && ROT="left"

      if [ "$OUT" = "$LAPTOP_OUTPUT" ]; then
        SCALE="$LAPTOP_SCALE"
      else
        SCALE="$(ext_scale_for "${BIG:-0}")"
      fi

      # Build enable line; primary on MIDDLE
      if [ "$OUT" = "${MIDDLE_OUT:-}" ]; then
        XR="$XR --output $OUT --primary --mode $MODE --scale ${SCALE}x${SCALE} --rotate $ROT --panning 0x0"
      else
        XR="$XR --output $OUT --mode $MODE --scale ${SCALE}x${SCALE} --rotate $ROT --panning 0x0"
      fi
    else
      XR="$XR --output $OUT --off"
    fi
  done

  echo "Applying base modes/scale/rotation..."
  echo "$XR"
  sh -c "$XR"

  # Position relative to middle (after scale/rotate). This avoids manual pixel math.
  if [ -n "${LEFT_OUT:-}" ] && [ "$LEFT_OUT" != "${MIDDLE_OUT:-}" ]; then
    echo "Placing $LEFT_OUT to the LEFT of $MIDDLE_OUT"
    xrandr --output "$LEFT_OUT" --left-of "$MIDDLE_OUT"
  fi
  if [ -n "${RIGHT_OUT:-}" ] && [ "$RIGHT_OUT" != "${MIDDLE_OUT:-}" ]; then
    echo "Placing $RIGHT_OUT to the RIGHT of $MIDDLE_OUT"
    xrandr --output "$RIGHT_OUT" --right-of "$MIDDLE_OUT"
  fi

  # Refresh wallpaper across heads
  set_wallpaper "$img"
}

# ===================== ARG PARSE (wallpaper + simple flags) ==================
SCALE_EXTERNAL="$DEFAULT_EXT_SCALE" # legacy (kept for compatibility)
IMG_NAME="$DEFAULT_WALLPAPER"

ARGS="$@"
while [ $# -gt 0 ]; do
  case "$1" in
    --big)
      SCALE_EXTERNAL="$BIG_EXT_SCALE"
      echo "Using larger (4K) scale for external monitors: $SCALE_EXTERNAL"
      shift
      ;;
    --sexy)
      IMG_NAME="$SEXY_WALLPAPER"
      echo "🔥 Applying sexy wallpaper: $IMG_NAME 🔥"
      shift
      ;;
    --left|--middle|--right)
      # Defer to configure_monitors
      shift 2 || true
      ;;
    *)
      if [ -f "$WALLPAPER_DIR/$1" ]; then
        IMG_NAME="$1"
        echo "Using custom wallpaper: $IMG_NAME"
      fi
      shift
      ;;
  esac
done

# ================================ RUN =======================================
# Re-run configure with the original argv so it can parse --left/--middle/--right
configure_monitors "$IMG_NAME" $ARGS
