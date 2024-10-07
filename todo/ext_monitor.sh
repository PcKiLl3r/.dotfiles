#!/usr/bin/env sh

# Get the status of the second monitor (HDMI-1)
status=$(xrandr --query | grep "HDMI-1")

# If the monitor is listed (connected or disconnected)
if [[ -n $status ]]; then
  # Check if the monitor is connected and currently active
  if xrandr --query | grep "HDMI-1 connected" | grep "1920x1080"; then
    xrandr --output HDMI-1 --off
    echo "Second monitor turned off."
  elif xrandr --query | grep "HDMI-1 connected"; then
    # If the monitor is connected but off, turn it on
    xrandr --output HDMI-1 --auto --right-of eDP-1 --scale 0.5x0.5
    echo "Second monitor turned on."
  else
    # If the monitor is disconnected but has a configuration, turn it off
    xrandr --output HDMI-1 --off
    echo "Second monitor configuration disabled."
  fi
else
  echo "HDMI-1 is not listed."
fi
