#!/usr/bin/env sh

case "$1" in
    on) xrandr --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --scale 1.5x1.5 --output HDMI-1 --mode 3840x2160 --pos 2880x0 --scale 1x1
    echo "Second monitor turned on." ;;
    off) xrandr --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --scale 1.5x1.5 --output HDMI-1 --off
    echo "Second monitor turned off." ;;
    *) printf '%s\n' "You must provide an argument: \"on\" or \"off\"" ;;
esac
