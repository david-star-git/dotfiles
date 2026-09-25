#!/usr/bin/env bash
# bluetooth-toggle.sh — instant optimistic flip, rfkill action, confirm.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

current=$(rfkill -J list bluetooth 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
token=$(new_click_token bluetooth)

if [[ "$current" == "unblocked" ]]; then
    eww_set bt_state 0
    log bluetooth "optimistic=0 (was on, blocking)"
    rfkill block bluetooth
    action_rc=$?
else
    eww_set bt_state 1
    log bluetooth "optimistic=1 (was off, unblocking)"
    rfkill unblock bluetooth
    action_rc=$?
fi

sleep 0.3
real=$(rfkill -J list bluetooth 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
if is_latest_click bluetooth "$token"; then
    if [[ "$real" == "unblocked" ]]; then
        eww_set bt_state 1
    else
        eww_set bt_state 0
    fi
fi
log bluetooth "confirmed=$real (rfkill exit $action_rc)"
