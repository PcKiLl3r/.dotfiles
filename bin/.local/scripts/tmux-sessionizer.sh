#!/usr/bin/env bash

# tmux-sessionizer

switch_to() {
  if [[ -z $TMUX ]]; then
    tmux attach-session -t "$1"
  else
    tmux switch-client -t "$1"
  fi
}

has_session() {
  tmux list-sessions 2>/dev/null | grep -q "^$1:"
}

hydrate() {
  if [[ -f "$2/.tmux-sessionizer" ]]; then
    tmux send-keys -t "$1" "source $2/.tmux-sessionizer" C-m
  elif [[ -f "$HOME/.tmux-sessionizer" ]]; then
    tmux send-keys -t "$1" "source $HOME/.tmux-sessionizer" C-m
  fi
}

# --- pick target ---
if [[ $# -eq 1 ]]; then
  selected=$1
else
  # If fzf is cancelled, exit immediately (prevents "_" session)
  if ! selected=$(
    {
            find -L ~/work -mindepth 1 -maxdepth 3 -type l,d -not -path "*/node_modules/*"
            find -L ~/learn -mindepth 1 -maxdepth 2 -type l,d -not -path "*/node_modules/*"
            find -L \
                ~/.dotfiles/bin/.local \
                ~/personal \
                ~/personal/custom-dev-exp \
                -mindepth 1 -maxdepth 1 -type l,d -not -path "*/node_modules/*"
            # ~/.config/nvim \
            printf '%s\n' "$HOME/.dotfiles"
            printf '%s\n' "$HOME/.config/nvim"
        } | fzf
  ); then
    exit 0
  fi
fi

# If nothing was selected (empty output), also exit safely
[[ -z $selected ]] && exit 0

selected_name=$(basename -- "$selected" | tr '.' '_')
tmux_running=$(pgrep tmux)

# Start first tmux if needed
if [[ -z $TMUX && -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  hydrate "$selected_name" "$selected"
  exit 0
fi

# Create the session if it doesn't exist yet
if ! has_session "$selected_name"; then
  tmux new-session -ds "$selected_name" -c "$selected"
  hydrate "$selected_name" "$selected"
fi

switch_to "$selected_name"
