#!/usr/bin/env bash
# Auto-detect and configure monitors based on current system

get_machine_type() {
    # Detect based on DMI info
    local product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "unknown")
    local vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "unknown")

    case "$product" in
        *"IdeaPad 330"*) echo "ideapad_330" ;;
        *"ThinkPad T16 Gen 2"*) echo "thinkpad_t16_gen2" ;;
        *) echo "generic" ;;
    esac
}

generate_monitor_config() {
    local machine_type="$1"
    local config_file="$HOME/.config/hypr/monitors.conf"

    case "$machine_type" in
        "ideapad_330")
            cat > "$config_file" << EOF
# IdeaPad 330 monitor configuration
monitor=eDP-1, 1920x1080@60, 0x0, 1
monitor=HDMI-A-1, 1920x1080@60, 1920x0, 1
EOF
            ;;
        "thinkpad_t16_gen2")
            cat > "$config_file" << EOF
# ThinkPad T16 Gen 2 monitor configuration
monitor=eDP-1, 2560x1440@60, 0x0, 1
monitor=DP-3, 3840x2160@60, 2560x0, 1.5
monitor=DP-4, 3840x2160@60, 0x0, 1.5
EOF
            ;;
        *)
            cat > "$config_file" << EOF
# Generic monitor configuration
monitor=, preferred, auto, 1
EOF
            ;;
    esac
}

MACHINE=$(get_machine_type)
echo "Detected machine: $MACHINE"
generate_monitor_config "$MACHINE"
