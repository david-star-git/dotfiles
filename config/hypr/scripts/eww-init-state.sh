#!/usr/bin/env bash
# eww-init-state.sh — runs once at Hyprland startup, BEFORE `eww open
# panel`/`eww open control_center`. Every toggle's defvar starts at a
# hardcoded default ("0"/"off") the moment eww loads the config — that
# default is very often wrong (e.g. WiFi is usually already on), and the
# periodic reconciler that would normally correct it runs on a timer
# (every 5s), not instantly. If a window opens and gets clicked before
# that first correction lands, the click acts on real state (correctly)
# while the display is still showing the stale default — which looks
# like it's toggling backwards. Running every check synchronously here,
# before anything is visible or clickable, closes that race entirely.
set -uo pipefail

log() {
    echo "[$(date '+%H:%M:%S')] init: $1" >> "$HOME/.cache/eww-toggle-debug.log"
}

wifi=$(timeout 2 rfkill -J list wlan 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
[[ "$wifi" == "unblocked" ]] && eww update wifi_state=1 || eww update wifi_state=0

bt=$(timeout 2 rfkill -J list bluetooth 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
[[ "$bt" == "unblocked" ]] && eww update bt_state=1 || eww update bt_state=0

hotspot_active() {
    local name mode
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        mode=$(nmcli -g 802-11-wireless.mode connection show "$name" 2>/dev/null)
        [[ "$mode" == "ap" ]] && return 0
    done < <(timeout 2 nmcli -t -f NAME connection show --active 2>/dev/null)
    return 1
}
if hotspot_active; then
    eww update hotspot_state=1
else
    eww update hotspot_state=0
fi

dnd=$(cat "$HOME/.cache/dnd-mode" 2>/dev/null || echo off)
eww update dnd_state="$dnd"

total=$(timeout 2 rfkill list 2>/dev/null | grep -c "^[0-9]" || true)
blocked=$(timeout 2 rfkill list 2>/dev/null | grep -c "Soft blocked: yes" || true)
if [[ "$total" -gt 0 && "$total" -eq "$blocked" ]]; then
    eww update airplane_state=1
else
    eww update airplane_state=0
fi

eww update tor_status=off

log "wifi=$wifi bt=$bt dnd=$dnd airplane_total=$total/$blocked"
