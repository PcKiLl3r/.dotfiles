````bash path=install-hyprland-tools.sh mode=EDIT
#!/bin/bash
# Hyprland ecosystem tools
sudo dnf install -y \
  waybar \           # Status bar (like i3bar)
  wofi \            # App launcher (like dmenu/rofi)
  mako \            # Notifications
  grim slurp \      # Screenshots
  wl-clipboard \    # Clipboard
  swaylock-effects  # Screen locker
````



````bash path=fedora-setup.sh mode=EDIT
# Enable RPM Fusion for additional packages
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Development essentials
sudo dnf install -y \
  git-delta \       # Better git diffs
  bat \            # Better cat
  eza \            # Better ls
  zoxide \         # Better cd
  starship         # Better prompt

# Angular CLI for frontend tooling
sudo npm install -g @angular/cli
````
