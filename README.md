# .dotfiles

### Stowing dotfiles

Use the `stow` script with a preset to install configuration for a given window manager:

```
./stow --mode i3
./stow --mode hyprland
```

Presets live in the `presets/` directory and list which folders get stowed for each setup.
Personal configuration files for setting up Linux workstations.

## Directory overview

- `bin/`, `nvim/`, `shell/`, `tmux/`, `xkb/`, `zsh/` – common configs used in either environment.
- `i3/` – configuration for the i3 window manager and status bar.
- `hypr/` – configuration for the Hyprland compositor.
- `personal/` and `work/` – machine‑specific overrides.

## Prerequisites

Install `git` and `stow` first.

### i3

Packages: `i3`, `i3status`, `dmenu`, `xorg`.

### Hyprland

Packages: `hyprland`, `waybar`, `wofi`, `grim`, `slurp`.

## Installation

1. Clone the repo and enter it:

   ```sh
   git clone https://example.com/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Export the repository path:

   ```sh
   export DOTFILES="$HOME/.dotfiles"
   ```

3. Stow the desired configuration:

   **i3:**

   ```sh
   ./stow --mode i3
   ```

   **Hyprland:**

   ```sh
   ./stow --mode hyprland
   ```

## Adding new configuration

- Add packages under the relevant folder and include them in the appropriate preset file.
- Run `./stow --mode <preset>` after updating presets to refresh symlinks.
