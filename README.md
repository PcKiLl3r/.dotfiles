# .dotfiles

### Stowing dotfiles

Use the `stow` script to install configuration for a given window manager:

```
./stow --mode i3
./stow --mode hyprland
```
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
   export STOW_FOLDERS="bin,nvim,shell,tmux,zsh,xkb,i3"
   ./stow
   ```

   **Hyprland:**

   ```sh
   export STOW_FOLDERS="bin,nvim,shell,tmux,zsh,xkb,hypr"
   ./stow
   ```

## Adding new configuration

- **Shared:** create a new top‑level folder and include it in `STOW_FOLDERS` for every setup.
- **WM specific:** place files under `i3/` or `hypr/` and only include the folder for that window manager.
- Run `./stow` after updating `STOW_FOLDERS` to refresh symlinks.
