#!/usr/bin/env bash
# dnd-reconcile.sh — periodic drift correction for the DND/Notifications
# tile (e.g. if something else toggles dnd-mode outside this widget).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

real=$(cat "$HOME/.cache/dnd-mode" 2>/dev/null || echo off)
eww_set dnd_state "$real"
echo "$real"
