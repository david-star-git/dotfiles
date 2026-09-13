#!/usr/bin/env bash
# dnd-toggle.sh — wraps the existing dnd.py --toggle with the same
# instant-flip-then-confirm pattern as the other tiles, without touching
# dnd.py itself (still used by keybinds elsewhere as-is).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

current=$(cat "$HOME/.cache/dnd-mode" 2>/dev/null || echo off)

if [[ "$current" == "off" ]]; then
    eww_set dnd_state on
    log dnd "optimistic=on"
else
    eww_set dnd_state off
    log dnd "optimistic=off"
fi

~/.config/hypr/scripts/dnd.py --toggle >/dev/null 2>&1
action_rc=$?

sleep 0.2
real=$(cat "$HOME/.cache/dnd-mode" 2>/dev/null || echo off)
eww_set dnd_state "$real"
log dnd "confirmed=$real (dnd.py exit $action_rc)"
