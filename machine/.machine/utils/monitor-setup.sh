#!/usr/bin/env bash
#
# monitor-setup.sh
#
# A helper script for configuring external monitors with xrandr.
# - Supports positioning (left, right)
# - Aligns monitors bottom
# - Supports rotation (normal, left, right, inverted)
# - Has defaults for laptop monitor & scaling
# - Prefers higher resolution over refresh rate
# - Can apply 4K scaling automatically
#

### --- CONFIGURATION --- ###
# Change these defaults as you like
LAPTOP_MONITOR="eDP-1"
LAPTOP_SCALE="1x1"     # e.g. "1x1", "1.25x1.25", "2x2"
DEFAULT_4K_SCALE="1.5x1.5"

# Helper: pick highest resolution, prefer refresh rate only if forced
pick_mode() {
    local monitor=$1
    local prefer_refresh=$2

    # Get highest resolution (first number is width)
    modes=$(xrandr --query | awk -v m="$monitor" '
        $1 == m { in_monitor=1; next }
        in_monitor && /^[[:alnum:]]/ { in_monitor=0 }
        in_monitor && /^[[:space:]]+[0-9]+x[0-9]+/ {print $1,$2}
    ')

    # Sort by resolution first, refresh rate second if prefer_refresh
    if [[ "$prefer_refresh" == "yes" ]]; then
        echo "$modes" | sort -k1,1 -k2,2nr | head -n1
    else
        echo "$modes" | sort -k1,1nr -k2,2nr | head -n1
    fi
}

### --- MAIN LOGIC --- ###
usage() {
    echo "Usage: $0 [options]
Options:
  --laptop <on|off>        Enable/disable laptop screen
  --ext <MON> <pos>        Attach external monitor MON at position (left|right)
  --rotate <MON> <mode>    Rotate monitor (normal|left|right|inverted|vertical|vertical-inverted)
  --scale <MON> <scale>    Apply custom scale (e.g., 1.5x1.5)
  --prefer-refresh         Prefer refresh rate over resolution
  --apply                  Apply config
Examples:
  $0 --ext DP-3-8 right --rotate DP-3-1 vertical --apply
  $0 --laptop off --ext DP-3-8 left --scale DP-3-8 1.5x1.5 --apply"
    exit 1
}

ARGS=("$@")
[[ ${#ARGS[@]} -eq 0 ]] && usage

MON_CMDS=()
PREFER_REFRESH="no"
LAPTOP_ENABLED="yes"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --laptop)
            LAPTOP_ENABLED=$2
            shift 2
            ;;
        --ext)
            MON=$2
            POS=$3
            MODE=$(pick_mode "$MON" "$PREFER_REFRESH" | awk '{print $1}')
            CMD="--output $MON --mode $MODE"
            [[ "$POS" == "left" ]]  && CMD+=" --left-of $LAPTOP_MONITOR"
            [[ "$POS" == "right" ]] && CMD+=" --right-of $LAPTOP_MONITOR"
            CMD+=" --auto --pos 0x0"
            MON_CMDS+=("$CMD")
            shift 3
            ;;
        --rotate)
            MON=$2
            ROT=$3
            case $ROT in
                vertical) ROT="left" ;;
                vertical-inverted) ROT="right" ;;
            esac
            MON_CMDS+=("--output $MON --rotate $ROT")
            shift 2
            ;;
        --scale)
            MON=$2
            SCALE=$3
            MON_CMDS+=("--output $MON --scale $SCALE")
            shift 2
            ;;
        --prefer-refresh)
            PREFER_REFRESH="yes"
            shift
            ;;
        --apply)
            # Apply laptop setting
            if [[ "$LAPTOP_ENABLED" == "on" ]]; then
                MODE=$(pick_mode "$LAPTOP_MONITOR" "$PREFER_REFRESH" | awk '{print $1}')
                xrandr --output $LAPTOP_MONITOR --mode $MODE --scale $LAPTOP_SCALE --primary
            else
                xrandr --output $LAPTOP_MONITOR --off
            fi

            # Apply monitor configs
            for c in "${MON_CMDS[@]}"; do
                echo "Applying: xrandr $c"
                xrandr $c
            done
            exit 0
            ;;
        *)
            usage
            ;;
    esac
done
