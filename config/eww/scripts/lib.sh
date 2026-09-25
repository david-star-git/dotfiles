#!/usr/bin/env bash
# lib.sh — shared helpers for the Control Center's instant-toggle pattern.
#
# Every toggle works the same way: read what's CURRENTLY DISPLAYED (via
# `eww get`, which only talks to the running eww daemon — no dependency
# on rfkill/nmcli/bluetoothctl/pkexec, so this step can never hang or
# silently do nothing), flip it instantly, THEN fire the real command
# with a timeout so a stuck external tool can't leave the UI stuck
# either. A periodic reconciler nudges the display back to truth every
# few seconds regardless, so it self-heals even if a confirm step is
# missed.
#
# Source this, don't execute it directly.

DEBUG_LOG="$HOME/.cache/eww-toggle-debug.log"

log() {
    echo "[$(date '+%H:%M:%S')] $1: $2" >> "$DEBUG_LOG"
}

# eww_get VAR [DEFAULT] — current value of an eww defvar, or DEFAULT if
# eww isn't reachable for some reason.
eww_get() {
    eww get "$1" 2>/dev/null || echo "${2:-}"
}

# eww_set VAR VALUE — pushes a value to an eww defvar immediately.
eww_set() {
    eww update "$1"="$2" >/dev/null 2>&1
}

# --- Spam-click safety -----------------------------------------------
# Every toggle does: flip optimistically, run the real (possibly slow)
# command, then write a "confirm" value once it's done. If you click
# again before that confirm lands, the OLD invocation's confirm can
# arrive after the NEW click's optimistic flip and stomp it — the tile
# looks like it ignored the second tap. These two helpers make "latest
# click wins": call new_click_token once right after the optimistic
# flip, then guard the delayed confirm write with is_latest_click.
CLICK_DIR="$HOME/.cache/eww-click-tokens"
mkdir -p "$CLICK_DIR" 2>/dev/null

new_click_token() {
    local key="$1" token
    token="$(date +%s%N)-$$"
    echo "$token" > "$CLICK_DIR/$key"
    echo "$token"
}

is_latest_click() {
    local key="$1" token="$2"
    [[ "$(cat "$CLICK_DIR/$key" 2>/dev/null)" == "$token" ]]
}
