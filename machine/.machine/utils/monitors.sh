#!/usr/bin/env sh
set -eu

WALLPAPER_DIR="$HOME/.machine/images/backgrounds"
DEFAULT_WALLPAPER="bg2.jpg"
SEXY_WALLPAPER="bg.png"

# === USER TUNABLES ===========================================================
LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP-1}"
LAPTOP_MODE="${LAPTOP_MODE:-1920x1200}"        # preferred laptop mode (used if set)
LAPTOP_SCALE="${LAPTOP_SCALE:-1.5}"            # your original laptop scale (normal non-mirror)
DEFAULT_EXT_SCALE="${DEFAULT_EXT_SCALE:-1.75}" # non-4K external default
BIG_EXT_SCALE="${BIG_EXT_SCALE:-1.0}"          # 4K "big" scaling
# ============================================================================

# -------- util: preferred mode for an output --------------------------------
preferred_mode() {
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

# -------- wallpaper logic ---------------------------------------------------
set_wallpaper() {
  local img="$1"
  echo "Setting wallpaper: $WALLPAPER_DIR/$img"
  pkill -x nitrogen >/dev/null 2>&1 || true
  nohup nitrogen --restore >/dev/null 2>&1 &
  for head in 0 1 2 3 4; do
    nohup nitrogen --set-zoom-fill "$WALLPAPER_DIR/$img" --head="$head" >/dev/null 2>&1 || break
    sleep 0.3
  done
}

# -------- helper: effective WxH from xrandr --current -----------------------
eff_wh() {
  xrandr --current | awk -v out="$1" '
    $1==out {
      if (match($0, / ([0-9]+)x([0-9]+)\+[0-9]+\+[0-9]+/ , a)) { print a[1], a[2]; exit }
    }
    END { print "0 0" }
  '
}

# -------- list modes / supports --------------------------------------------
modes_of() {
  xrandr | awk -v out="$1" '
    $0 ~ "^"out" connected" { s=1; next }
    s==1 && $0 ~ /^[[:space:]]+[0-9]/ { print $1; next }
    s==1 && $0 !~ /^[[:space:]]/ { exit }
  '
}
output_supports_mode() {
  modes_of "$1" | awk -v m="$2" '$0==m {found=1} END{ exit found?0:1 }'
}

# -------- parse "NAME[:big][:vertical|vertical-right]" ----------------------
# Out vars (by prefix): <PFX>_OUT, <PFX>_BIG, <PFX>_VERT, <PFX>_ROTATE
parse_spec() {
  local pfx="$1"; local tok="${2:-}"
  [ -z "$tok" ] && return 0
  eval "${pfx}_BIG=0"
  eval "${pfx}_VERT=0"
  eval "${pfx}_ROTATE='left'"

  IFS=':' read -r name flag1 flag2 <<EOF
$tok
EOF

  for f in "$flag1" "$flag2"; do
    case "${f:-}" in
      big)                           eval "${pfx}_BIG=1" ;;
      vertical|portrait)             eval "${pfx}_VERT=1"; eval "${pfx}_ROTATE='left'" ;;
      vertical-right|portrait-right) eval "${pfx}_VERT=1"; eval "${pfx}_ROTATE='right'" ;;
      "" ) : ;;
      *) : ;;
    esac
  done
  eval "${pfx}_OUT=\$name"
}

# -------- choose autos for auto1/auto2 --------------------------------------
resolve_auto_outputs() {
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
  if [ "${1:-0}" = "1" ]; then
    printf "%s" "$BIG_EXT_SCALE"
  else
    printf "%s" "$DEFAULT_EXT_SCALE"
  fi
}

# -------- main monitor config ------------------------------------------------
configure_monitors() {
  local img="$1"

  # defaults
  LEFT_OUT="";   MIDDLE_OUT="";   RIGHT_OUT=""
  LEFT_BIG=0;    MIDDLE_BIG=0;    RIGHT_BIG=0
  LEFT_VERT=0;   MIDDLE_VERT=0;   RIGHT_VERT=0
  LEFT_ROTATE='left'; MIDDLE_ROTATE='left'; RIGHT_ROTATE='left'
  MIRROR_ROLE=""
  EXTERNALS_ONLY=0    # when 1, disable laptop and keep externals

  # parse args for specs/flags
  while [ $# -gt 0 ]; do
    case "$1" in
      --left)   parse_spec LEFT   "${2:-}"; shift 2 ;;
      --middle) parse_spec MIDDLE "${2:-}"; shift 2 ;;
      --right)  parse_spec RIGHT  "${2:-}"; shift 2 ;;
      --mirror) MIRROR_ROLE="${2:-}"; shift 2 ;;
      --externals-only|--no-laptop) EXTERNALS_ONLY=1; shift ;;
      --big|--sexy) shift ;; # handled earlier
      -*) shift ;;
      *)  shift ;;
    esac
  done

  # default middle to laptop if not set
  if [ -z "${MIDDLE_OUT:-}" ]; then
    MIDDLE_OUT="$LAPTOP_OUTPUT"
  fi

  resolve_auto_outputs

  # -------------------- MIRROR MODE (visual clone) ---------------------------
  if [ -n "${MIRROR_ROLE:-}" ]; then
    # pick external to mirror to
    pick_external_for_side() {
      side="$1"
      if [ "$side" = "left" ]; then
        cand1="${LEFT_OUT:-}"; cand2="${MIDDLE_OUT:-}"; cand3="${RIGHT_OUT:-}"
      else
        cand1="${RIGHT_OUT:-}"; cand2="${MIDDLE_OUT:-}"; cand3="${LEFT_OUT:-}"
      fi
      for c in "$cand1" "$cand2" "$cand3"; do
        [ -n "$c" ] && [ "$c" != "$LAPTOP_OUTPUT" ] && { echo "$c"; return 0; }
      done
      echo ""; return 1
    }

    MIRROR_OUT="$(pick_external_for_side "$MIRROR_ROLE" || true)"
    # the "other" external (keep extended)
    if [ "$MIRROR_ROLE" = "left" ]; then
      OTHER_OUT="${RIGHT_OUT:-}"
    else
      OTHER_OUT="${LEFT_OUT:-}"
    fi
    [ -n "$OTHER_OUT" ] && [ "$OTHER_OUT" = "$LAPTOP_OUTPUT" ] && OTHER_OUT=""

    if [ -z "${MIRROR_OUT:-}" ]; then
      echo "Mirror requested for '$MIRROR_ROLE' but no external output found on that side. Aborting mirror."
      return 0
    fi

    # Set external (mirror target) to native 1x1 at temporary origin (will position later)
    EXT_MODE="$(preferred_mode "$MIRROR_OUT")"; [ -z "$EXT_MODE" ] && EXT_MODE="auto"
    XR="xrandr"
    if [ "$EXT_MODE" = "auto" ]; then
      XR="$XR --output $MIRROR_OUT --auto --scale 1x1 --rotate normal --panning 0x0 --pos 0x0"
    else
      XR="$XR --output $MIRROR_OUT --mode $EXT_MODE --scale 1x1 --rotate normal --panning 0x0 --pos 0x0"
    fi

    # Prep laptop at base mode 1x1 (to read base size properly)
    LAP_MODE="${LAPTOP_MODE:-$(preferred_mode "$LAPTOP_OUTPUT")}"
    [ -z "$LAP_MODE" ] && LAP_MODE="auto"
    if [ "$LAP_MODE" = "auto" ]; then
      XR="$XR --output $LAPTOP_OUTPUT --auto --scale 1x1 --rotate normal --panning 0x0 --pos 0x0"
    else
      XR="$XR --output $LAPTOP_OUTPUT --mode $LAP_MODE --scale 1x1 --rotate normal --panning 0x0 --pos 0x0"
    fi

    # Prep OTHER_OUT (if present) with its flags (not mirrored)
    if [ -n "${OTHER_OUT:-}" ]; then
      ROLE=""; BIG=0; VERT=0; ROT_DIR="left"
      if   [ "$OTHER_OUT" = "${LEFT_OUT:-}"   ]; then ROLE="LEFT";   BIG=$LEFT_BIG;   VERT=$LEFT_VERT;   ROT_DIR="$LEFT_ROTATE"
      elif [ "$OTHER_OUT" = "${MIDDLE_OUT:-}" ]; then ROLE="MIDDLE"; BIG=$MIDDLE_BIG; VERT=$MIDDLE_VERT; ROT_DIR="$MIDDLE_ROTATE"
      elif [ "$OTHER_OUT" = "${RIGHT_OUT:-}"  ]; then ROLE="RIGHT";  BIG=$RIGHT_BIG;  VERT=$RIGHT_VERT;  ROT_DIR="$RIGHT_ROTATE"
      fi
      O_MODE="$(preferred_mode "$OTHER_OUT")"; [ -z "$O_MODE" ] && O_MODE="auto"
      O_ROT="normal"; [ "${VERT:-0}" = "1" ] && { [ "$ROT_DIR" = "right" ] && O_ROT="right" || O_ROT="left"; }
      O_SCALE="$(ext_scale_for "${BIG:-0}")"
      if [ "$O_MODE" = "auto" ]; then
        XR="$XR --output $OTHER_OUT --auto --scale ${O_SCALE}x${O_SCALE} --rotate $O_ROT --panning 0x0"
      else
        XR="$XR --output $OTHER_OUT --mode $O_MODE --scale ${O_SCALE}x${O_SCALE} --rotate $O_ROT --panning 0x0"
      fi
    fi

    echo "Priming mirror layout..."
    echo "$XR"; sh -c "$XR"

    # Read sizes
    set -- $(eff_wh "$MIRROR_OUT"); EXT_W=${1:-0}; EXT_H=${2:-0}
    set -- $(eff_wh "$LAPTOP_OUTPUT"); LAP_W=${1:-0}; LAP_H=${2:-0}
    if [ "$EXT_W" -le 0 ] || [ "$EXT_H" -le 0 ] || [ "$LAP_W" -le 0 ] || [ "$LAP_H" -le 0 ]; then
      echo "Could not determine sizes for smart mirror; aborting mirror."
      return 0
    fi

    # Compute laptop scale so its CRTC matches external's native canvas
    # sx = extW/lapW ; sy = extH/lapH
    calc="$(python3 - <<PY || echo "1.0 1.0"
extw=$EXT_W; exth=$EXT_H; lapw=$LAP_W; laph=$LAP_H
print(f"{extw/lapw:.6f} {exth/laph:.6f}")
PY
)"
    LAP_SX=$(printf "%s" "$calc" | awk '{print $1}')
    LAP_SY=$(printf "%s" "$calc" | awk '{print $2}')

    # Build final command: mirror (overlap) laptop with MIRROR_OUT, keep OTHER_OUT extended.
    XR="xrandr"

    # mirror pair at X_MIR; other external (if any) at X_OTHER=0
    WL=0; HL=0
    if [ -n "${OTHER_OUT:-}" ]; then
      # make sure it's 1: placed; exact pos after we know size
      set -- $(eff_wh "$OTHER_OUT"); WL=${1:-0}; HL=${2:-0}
      XR="$XR --output $OTHER_OUT --pos 0x0"   # temp Y, will bottom-align after
    fi

    X_MIR=$WL
    # MIRROR_OUT native 1x1, no panning
    XR="$XR --output $MIRROR_OUT --scale 1x1 --rotate normal --panning 0x0 --pos ${X_MIR}x0"
    # Laptop scaled to match MIRROR_OUT; no panning (CRTC already matches)
    if [ "$LAP_MODE" = "auto" ]; then
      XR="$XR --output $LAPTOP_OUTPUT --primary --auto --scale ${LAP_SX}x${LAP_SY} --rotate normal --panning 0x0 --pos ${X_MIR}x0"
    else
      XR="$XR --output $LAPTOP_OUTPUT --primary --mode $LAP_MODE --scale ${LAP_SX}x${LAP_SY} --rotate normal --panning 0x0 --pos ${X_MIR}x0"
    fi

    # Turn off truly unused outputs
    ALL_OUTS="$(xrandr | awk '/ connected| disconnected/ { print $1 }')"
    for OUT in $ALL_OUTS; do
      if [ "$OUT" != "$LAPTOP_OUTPUT" ] && [ "$OUT" != "$MIRROR_OUT" ] && [ "$OUT" != "${OTHER_OUT:-__none__}" ]; then
        XR="$XR --output $OUT --off"
      fi
    done

    echo "Applying SMART MIRROR (target=$MIRROR_OUT, laptop scale ${LAP_SX}x${LAP_SY})..."
    echo "$XR"; sh -c "$XR"

    # Bottom-align: compute heights after scaling
    WM=0; HM=0; WL2=0; HL2=0
    set -- $(eff_wh "$MIRROR_OUT"); WM=${1:-0}; HM=${2:-0}
    if [ -n "${OTHER_OUT:-}" ]; then
      set -- $(eff_wh "$OTHER_OUT"); WL2=${1:-0}; HL2=${2:-0}
    fi
    MAXH=$HM; [ "$HL2" -gt "$MAXH" ] && MAXH=$HL2
    Y_MIR=$((MAXH - HM))
    Y_OTHER=$((MAXH - HL2))

    [ -n "${OTHER_OUT:-}" ] && { echo "Pos $OTHER_OUT at 0x${Y_OTHER}"; xrandr --output "$OTHER_OUT" --pos 0x${Y_OTHER}; }
    echo "Pos $MIRROR_OUT at ${X_MIR}x${Y_MIR}"
    xrandr --output "$MIRROR_OUT" --pos ${X_MIR}x${Y_MIR}
    echo "Pos $LAPTOP_OUTPUT at ${X_MIR}x${Y_MIR} (overlap mirror)"
    xrandr --output "$LAPTOP_OUTPUT" --pos ${X_MIR}x${Y_MIR}

    # Optionally disable laptop in mirror mode if requested
    if [ "$EXTERNALS_ONLY" -eq 1 ]; then
      echo "Externals-only: turning laptop OFF."
      xrandr --output "$LAPTOP_OUTPUT" --off
    fi

    set_wallpaper "$img"
    return 0
  fi

  # -------------------- NORMAL MULTI-MONITOR LAYOUT --------------------------
  USED_OUTPUTS=""
  add_used() { USED_OUTPUTS="$USED_OUTPUTS $1"; }
  for item in LEFT MIDDLE RIGHT; do
    eval OUT=\$${item}_OUT
    [ -n "${OUT:-}" ] && add_used "$OUT"
  done

  # Ensure laptop appears somewhere unless externals-only requested
  if [ "$EXTERNALS_ONLY" -eq 0 ]; then
    if ! printf "%s\n" $USED_OUTPUTS | grep -q "^$LAPTOP_OUTPUT$"; then
      if [ -z "${MIDDLE_OUT:-}" ] || [ "$MIDDLE_OUT" != "$LAPTOP_OUTPUT" ]; then
        MIDDLE_OUT="$LAPTOP_OUTPUT"
        add_used "$LAPTOP_OUTPUT"
      fi
    fi
  fi

  XR="xrandr"
  ALL_OUTS="$(xrandr | awk '/ connected| disconnected/ { print $1 }')"

  for OUT in $ALL_OUTS; do
    if printf "%s\n" $USED_OUTPUTS | grep -q "^$OUT$"; then
      ROLE=""; BIG=0; VERT=0; ROT_DIR="left"
      if   [ "$OUT" = "${LEFT_OUT:-}"   ]; then ROLE="LEFT";   BIG=$LEFT_BIG;   VERT=$LEFT_VERT;   ROT_DIR="$LEFT_ROTATE"
      elif [ "$OUT" = "${MIDDLE_OUT:-}" ]; then ROLE="MIDDLE"; BIG=$MIDDLE_BIG; VERT=$MIDDLE_VERT; ROT_DIR="$MIDDLE_ROTATE"
      elif [ "$OUT" = "${RIGHT_OUT:-}"  ]; then ROLE="RIGHT";  BIG=$RIGHT_BIG;  VERT=$RIGHT_VERT;  ROT_DIR="$RIGHT_ROTATE"
      fi

      # Mode
      if [ "$OUT" = "$LAPTOP_OUTPUT" ] && [ -n "${LAPTOP_MODE:-}" ]; then
        MODE="$LAPTOP_MODE"
      else
        MODE="$(preferred_mode "$OUT")"
        [ -z "$MODE" ] && MODE="auto"
      fi

      # Rotation
      ROT="normal"
      if [ "${VERT:-0}" = "1" ]; then
        case "$ROT_DIR" in right) ROT="right";; *) ROT="left";; esac
      fi

      # Scale
      if [ "$OUT" = "$LAPTOP_OUTPUT" ]; then
        SCALE="$LAPTOP_SCALE"
      else
        SCALE="$(ext_scale_for "${BIG:-0}")"
      fi

      # Enable; primary on MIDDLE; clear panning
      if [ "$OUT" = "${MIDDLE_OUT:-}" ]; then
        XR="$XR --output $OUT --primary --mode $MODE --scale ${SCALE}x${SCALE} --rotate $ROT --panning 0x0"
      else
        XR="$XR --output $OUT --mode $MODE --scale ${SCALE}x${SCALE} --rotate $ROT --panning 0x0"
      fi
    else
      XR="$XR --output $OUT --off"
    fi
  done

  # If externals-only, explicitly turn laptop off
  if [ "$EXTERNALS_ONLY" -eq 1 ]; then
    XR="$XR --output $LAPTOP_OUTPUT --off"
  fi

  echo "Applying base modes/scale/rotation..."
  echo "$XR"
  sh -c "$XR"

  # ---- Bottom-aligned placement (explicit positions) -----------------------
  WL=0; HL=0; WM=0; HM=0; WR=0; HR=0

  if [ -n "${LEFT_OUT:-}" ]; then
    set -- $(eff_wh "$LEFT_OUT");  WL=${1:-0}; HL=${2:-0}
  fi
  if [ -n "${MIDDLE_OUT:-}" ]; then
    set -- $(eff_wh "$MIDDLE_OUT"); WM=${1:-0}; HM=${2:-0}
  fi
  if [ -n "${RIGHT_OUT:-}" ]; then
    set -- $(eff_wh "$RIGHT_OUT");  WR=${1:-0}; HR=${2:-0}
  fi

  X_CUR=0
  X_LEFT=$X_CUR;   [ -n "${LEFT_OUT:-}" ]   && X_CUR=$((X_CUR + WL))
  X_MID=$X_CUR;    [ -n "${MIDDLE_OUT:-}" ] && X_CUR=$((X_CUR + WM))
  X_RIGHT=$X_CUR;  [ -n "${RIGHT_OUT:-}" ]  && X_CUR=$((X_CUR + WR))

  MAXH=$HM
  [ "$HL" -gt "$MAXH" ] && MAXH=$HL
  [ "$HR" -gt "$MAXH" ] && MAXH=$HR

  Y_LEFT=$((MAXH - HL))
  Y_MID=$((MAXH - HM))
  Y_RIGHT=$((MAXH - HR))

  [ -n "${LEFT_OUT:-}" ]   && { echo "Pos $LEFT_OUT at ${X_LEFT}x${Y_LEFT}";   xrandr --output "$LEFT_OUT"   --pos ${X_LEFT}x${Y_LEFT}; }
  [ -n "${MIDDLE_OUT:-}" ] && { echo "Pos $MIDDLE_OUT at ${X_MID}x${Y_MID}";    xrandr --output "$MIDDLE_OUT" --pos ${X_MID}x${Y_MID}; }
  [ -n "${RIGHT_OUT:-}" ]  && { echo "Pos $RIGHT_OUT at ${X_RIGHT}x${Y_RIGHT}"; xrandr --output "$RIGHT_OUT"  --pos ${X_RIGHT}x${Y_RIGHT}; }

  set_wallpaper "$img"
}

# ===================== ARG PARSE (wallpaper + simple flags) ==================
SCALE_EXTERNAL="$DEFAULT_EXT_SCALE"
IMG_NAME="$DEFAULT_WALLPAPER"

ARGS="$@"
while [ $# -gt 0 ]; do
  case "$1" in
    --big)    SCALE_EXTERNAL="$BIG_EXT_SCALE"; echo "Using larger (4K) scale: $SCALE_EXTERNAL"; shift ;;
    --sexy)   IMG_NAME="$SEXY_WALLPAPER"; echo "🔥 Applying sexy wallpaper: $IMG_NAME 🔥"; shift ;;
    --left|--middle|--right|--mirror) shift 2 || true ;;
    --externals-only|--no-laptop) shift ;;
    *)
      if [ -f "$WALLPAPER_DIR/$1" ]; then IMG_NAME="$1"; echo "Using custom wallpaper: $IMG_NAME"; fi
      shift
      ;;
  esac
done

# ================================ RUN =======================================
configure_monitors "$IMG_NAME" $ARGS
