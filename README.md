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

- `bin/` – helper scripts placed on the `PATH`.
- `i3/.config/i3` – configuration for the i3 window manager.
- `nvim/.config/nvim` – Neovim settings and plugins.
- `shell/.config` – shared shell configuration.
- `tmux/` – tmux configuration files.
- `xkb/.config/xkb` – custom keyboard layout files.
- `zsh/` – zsh specific settings.
- `personal/` and `work/` – machine‑specific overrides.
- Add a `hypr/` directory for Hyprland configuration when using Wayland.

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

- **Shared:** create a new top‑level folder and include it in the appropriate preset files.
- **WM specific:** place files under `i3/` or `hypr/` and update only the matching preset.
- Run `./stow --mode <preset>` after updating presets to refresh symlinks.
