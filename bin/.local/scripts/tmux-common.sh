
#!/usr/bin/env bash

#tmux-common.sh
# ===================== CONFIG (edit here) =====================
# Project roots with min/max depth: "path:min:max"
PROJECT_SCOPES=(
  "$HOME/work:1:3"
  "$HOME/learn:1:2"
  "$HOME/.config/nvim:1:1"
  "$HOME/.dotfiles/bin/.local:1:1"
  "$HOME/Downloads:1:1"
  "$HOME/personal:1:1"
  "$HOME/personal/custom-dev-exp:1:1"
)

# Exclude patterns for find
EXCLUDES=("*/node_modules/*")

# Hook files checked in order (keeps both names for compatibility)
HOOK_FILES=(".ready-tmux" ".tmux-sessionizer")

# fzf options
FZF_OPTS="--ansi --no-sort --height=80% --reverse"
# =============================================================

set -euo pipefail

is_tmux_attached() { [[ -n "${TMUX-}" ]]; }
tmux_server_running() { pgrep tmux >/dev/null 2>&1; }

has_session() {
  local name="$1"
  tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qx -- "$name"
}

switch_to() {
  local name="$1"
  if is_tmux_attached; then tmux switch-client -t "$name"; else tmux attach-session -t "$name"; fi
}

start_detached_session() { tmux new-session -ds "$1" -c "$2"; }

list_projects() {
  for spec in "${PROJECT_SCOPES[@]}"; do
    IFS=: read -r root mind maxd <<<"$spec"
    local -a excl_args=()
    for pat in "${EXCLUDES[@]}"; do excl_args+=(-not -path "$pat"); done
    find -L "$root" -mindepth "$mind" -maxdepth "$maxd" \( -type l -o -type d \) "${excl_args[@]}"
  done | awk '!seen[$0]++'
}

pick_with_fzf() { list_projects | fzf ${FZF_OPTS}; }

find_upwards_hook() {
  local dir="$1" cur="$1"
  while [[ "$cur" != "$HOME" && "$cur" != "/" ]]; do
    for hook in "${HOOK_FILES[@]}"; do
      [[ -f "$cur/$hook" ]] && { echo "$cur/$hook"; return 0; }
    done
    cur="$(dirname "$cur")"
  done
  for hook in "${HOOK_FILES[@]}"; do
    [[ -f "$HOME/$hook" ]] && { echo "$HOME/$hook"; return 0; }
  done
  return 1
}

hydrate_local_then_home() {
  local session="$1" dir="$2"
  for hook in "${HOOK_FILES[@]}"; do
    if [[ -f "$dir/$hook" ]]; then tmux send-keys -t "$session" "source '$dir/$hook'" C-m; return; fi
  done
  for hook in "${HOOK_FILES[@]}"; do
    if [[ -f "$HOME/$hook" ]]; then tmux send-keys -t "$session" "source '$HOME/$hook'" C-m; return; fi
  done
}

hydrate_bubble_up() {
  local session="$1" dir="$2" hook
  if hook="$(find_upwards_hook "$dir")"; then tmux send-keys -t "$session" "source '$hook'" C-m; fi
}

open_tmux_session() {
  local selected="$1" mode="$2"
  [[ -z "$selected" ]] && return 0

  local name; name="$(basename "$selected" | tr . _ )"
  local hydrate_fn
  case "$mode" in
    local) hydrate_fn=hydrate_local_then_home ;;
    up)    hydrate_fn=hydrate_bubble_up ;;
    *)     echo "Unknown mode: $mode" >&2; return 2 ;;
  esac

  if ! tmux_server_running && ! is_tmux_attached; then
    start_detached_session "$name" "$selected"
    tmux start-server >/dev/null 2>&1 || true
    "$hydrate_fn" "$name" "$selected"
    tmux attach-session -t "$name"
    return 0
  fi

  if ! has_session "$name"; then
    start_detached_session "$name" "$selected"
    "$hydrate_fn" "$name" "$selected"
  fi

  switch_to "$name"
}
