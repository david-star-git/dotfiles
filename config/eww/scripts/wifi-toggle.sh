#!/usr/bin/env bash
# wifi-toggle.sh — flips wifi_state instantly, runs the real rfkill
# command, then confirms/corrects against what actually happened.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

current=$(rfkill -J list wlan 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')

if [[ "$current" == "unblocked" ]]; then
    eww_set wifi_state 0
    log wifi "optimistic=0 (was on, blocking)"
    rfkill block wlan
    action_rc=$?
else
    eww_set wifi_state 1
    log wifi "optimistic=1 (was off, unblocking)"
    rfkill unblock wlan
    action_rc=$?
fi

sleep 0.3
real=$(rfkill -J list wlan 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
if [[ "$real" == "unblocked" ]]; then
    eww_set wifi_state 1
else
    eww_set wifi_state 0
fi
log wifi "confirmed=$real (rfkill exit $action_rc)"
