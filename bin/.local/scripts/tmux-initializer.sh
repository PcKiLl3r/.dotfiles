
#!/usr/bin/env bash

#tmux-initializer

find_ready_tmux() {
    local current_dir="$1"
    while [[ "$current_dir" != "$HOME" && "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.ready-tmux" ]]; then
            echo "$current_dir/.ready-tmux"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    if [[ -f "$HOME/.ready-tmux" ]]; then
        echo "$HOME/.ready-tmux"
        return 0
    fi
    return 1
}

switch_to() {
    if [[ -z $TMUX ]]; then
        tmux attach-session -t "$1"
    else
        tmux switch-client -t "$1"
    fi
}

has_session() {
    tmux list-sessions | grep -q "^$1:"
}

hydrate() {
    local session="$1"
    local dir="$2"

    if [[ -f "$dir/.ready-tmux" ]]; then
        tmux send-keys -t "$session" "source $dir/.ready-tmux" C-m
        return
    fi

    local ready_tmux
    ready_tmux=$(find_ready_tmux "$dir")
    if [[ -n "$ready_tmux" ]]; then
        tmux send-keys -t "$session" "source $ready_tmux" C-m
    fi
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(
        {
            find -L ~/work -mindepth 1 -maxdepth 3 -type l,d -not -path "*/node_modules/*"
            find -L ~/learn -mindepth 1 -maxdepth 2 -type l,d -not -path "*/node_modules/*"
            find -L \
                ~/.config/nvim \
                ~/.dotfiles/bin/.local \
                ~/personal \
                ~/personal/custom-dev-exp \
                ~/.config/nvim \
                -mindepth 1 -maxdepth 1 -type l,d -not -path "*/node_modules/*"
            printf '%s\n' "$HOME/.dotfiles"
        } | fzf
    )
fi

[[ -z $selected ]] && exit 0

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# If tmux is NOT running, start a server first
if [[ -z "$TMUX" && -z "$tmux_running" ]]; then
    tmux new-session -ds "$selected_name" -c "$selected"
    tmux start-server  # <-- Ensure the server is running
    hydrate "$selected_name" "$selected"
    tmux attach-session -t "$selected_name"
    exit 0
fi

if ! has_session "$selected_name"; then
    tmux new-session -ds "$selected_name" -c "$selected"
    hydrate "$selected_name" "$selected"
fi

switch_to "$selected_name"
