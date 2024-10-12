#!/usr/bin/env sh

# Detect if the second monitor (HDMI-1) is connected
if xrandr | grep "HDMI-1 connected" > /dev/null; then
    # HDMI-1 is connected, configure it
    echo "Second monitor detected. Turning on..."
    xrandr --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --scale 1.5x1.5 --output HDMI-1 --mode 3840x2160 --pos 2880x0 --scale 1x1
else
    # HDMI-1 is not connected, turn it off
    echo "No second monitor detected. Turning off..."
    xrandr --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --scale 1.5x1.5 --output HDMI-1 --off
fi