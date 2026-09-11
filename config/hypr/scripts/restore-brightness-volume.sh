#!/usr/bin/env bash
# restore-brightness-volume.sh — reapplies the last brightness/volume you
# set, since neither brightnessctl nor a fresh PipeWire session remembers
# it across a reboot on its own. Run once at Hyprland startup, before eww
# starts polling — if there's nothing saved yet (first run), it's a no-op.
set -uo pipefail

BRIGHTNESS_FILE="$HOME/.cache/saved-brightness"
VOLUME_FILE="$HOME/.cache/saved-volume"

if [[ -f "$BRIGHTNESS_FILE" ]]; then
    saved=$(cat "$BRIGHTNESS_FILE")
    [[ "$saved" =~ ^[0-9]+$ ]] && brightnessctl set "${saved}%" >/dev/null 2>&1
fi

if [[ -f "$VOLUME_FILE" ]]; then
    saved=$(cat "$VOLUME_FILE")
    [[ "$saved" =~ ^[0-9]+$ ]] && pamixer --set-volume "$saved" >/dev/null 2>&1
fi
