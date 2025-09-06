## Current State Analysis

## Suggested Improvements for i3-like Hyprland Experience

### 1. Enhanced Hyprland Configuration
Your current `hyprland.conf` is basic. For i3-like behavior, consider adding:

```` path=hypr/.config/hypr/hyprland.conf mode=EDIT
# Workspace behavior (i3-like)
workspace = 1, monitor:eDP-1, default:true
workspace = 2, monitor:eDP-1
workspace = 3, monitor:eDP-1
workspace = 4, monitor:eDP-1
workspace = 5, monitor:eDP-1

# Window rules for i3-like tiling
windowrulev2 = tile, class:.*
windowrulev2 = float, class:pavucontrol
windowrulev2 = float, class:blueman-manager

# i3-like keybindings
bind = $mod, Return, exec, alacritty
bind = $mod, d, exec, wofi --show drun
bind = $mod, q, killactive
bind = $mod SHIFT, e, exit

# Workspace switching (i3-style)
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5

# Move windows to workspaces
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

# Window focus (vim-like)
bind = $mod, h, movefocus, l
bind = $mod, l, movefocus, r
bind = $mod, k, movefocus, u
bind = $mod, j, movefocus, d
````

### 4. Update Your Utility Scripts
Your `hdmi` script uses xrandr (X11). Create a Hyprland version:

````bash path=bin/.local/utils/hdmi-hypr mode=EDIT
#!/usr/bin/env bash
# Hyprland monitor configuration
hyprctl keyword monitor "eDP-1,1920x1200,0x0,1"
hyprctl keyword monitor "HDMI-A-1,1920x1080,1920x0,1"
````

### 5. Waybar Configuration
Since you're using waybar, create a config that matches your i3status setup:

````json path=waybar/.config/waybar/config mode=EDIT
{
    "layer": "top",
    "position": "top",
    "height": 24,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["network", "bluetooth", "battery", "clock"],

    "hyprland/workspaces": {
        "format": "{id}",
        "on-click": "activate"
    },

    "clock": {
        "format": "{:%Y-%m-%d %H:%M}"
    },

    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    }
}
````

### 6. Environment Detection
Add Wayland detection to your shell config:

````bash path=shell/.config/personal/env mode=EDIT
# Wayland/X11 detection and setup
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    alias xclip='wl-copy'
    alias xsel='wl-paste'
else
    # X11 setup
    setxkbmap -option caps:ctrl_modifier
fi
````

4. **Smart preset system** for different machines

## Additional Recommendations

2. **Create Hyprland-specific presets** in `resources/presets/`
3. **Add screenshot/screen recording tools** for Wayland
4. **Consider adding `hypridle` and `hyprlock`** for power management

Your setup is already quite sophisticated - these changes should help make Hyprland feel more like your familiar i3 environment while taking advantage of Wayland's benefits!
