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
