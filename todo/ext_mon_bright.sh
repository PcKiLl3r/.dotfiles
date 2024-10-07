#!/usr/bin/env sh

#if [ "$#" -ne 1 ] ; then
#        echo "$0: exactly 1 arguments expected, recieved: $#"
#        exit 3
#fi

#if [$1 != "up" -a $1 != 'down'] ; then
#        echo "$0: first argument must be string "up" or "down""
#        exit 1
#fi

#if xrandr --query | grep "HDMI-1 connected"; then
    brightnessCmd=$1
    if [[ $brightnessCmd == "up" ]]; then
        xrandr --output HDMI-1 --brightness 1.0 --gamma 0.5:0.5:0.5
        echo "Second monitor turned bright"
    elif [[ $brightnessCmd == "down" ]]; then
        xrandr --output HDMI-1 --brightness 0.6 --gamma 0.5:0.5:0.5

        echo "Second monitor turned dark"
    else
        xrandr --output HDMI-1 --brightness 0.6 --gamma 0.5:0.5:0.5
        echo "Default bright..."
    fi
#else
#  echo "HDMI-1 is not connected."
#fi
