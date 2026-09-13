#!/usr/bin/env bash
# hotspot-toggle.sh — instant optimistic flip, then the real nmcli
# hotspot command, then confirm.
#
# Finds the active hotspot connection by its actual defining property
# (WiFi access-point mode), not by assuming it's named "Hotspot" — nmcli
# doesn't guarantee that exact name, which was why "turn off" wasn't
# reliably finding the right connection to bring down.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

active_ap_connection() {
    # Look through active connections for one whose wifi mode is "ap".
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        mode=$(nmcli -g 802-11-wireless.mode connection show "$name" 2>/dev/null)
        if [[ "$mode" == "ap" ]]; then
            echo "$name"
            return 0
        fi
    done < <(nmcli -t -f NAME connection show --active 2>/dev/null)
    return 1
}

current=$(active_ap_connection || true)

if [[ -n "$current" ]]; then
    eww_set hotspot_state 0
    log hotspot "optimistic=0 (was on as '$current', stopping)"
    nmcli connection down "$current" >/dev/null 2>&1
    action_rc=$?
else
    eww_set hotspot_state 1
    log hotspot "optimistic=1 (was off, starting)"
    nmcli device wifi hotspot >/dev/null 2>&1
    action_rc=$?
fi

sleep 0.5
if active_ap_connection >/dev/null; then
    eww_set hotspot_state 1
else
    eww_set hotspot_state 0
fi
log hotspot "confirmed (nmcli exit $action_rc)"
