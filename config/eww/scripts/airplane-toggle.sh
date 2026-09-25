#!/usr/bin/env bash
# airplane-toggle.sh — instant optimistic flip, rfkill block/unblock all,
# confirm. Already proven working — kept on rfkill exactly as before,
# just adding the instant-feedback wrapper for consistency with the rest.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

is_all_blocked() {
    local total blocked
    total=$(rfkill list 2>/dev/null | grep -c "^[0-9]" || true)
    blocked=$(rfkill list 2>/dev/null | grep -c "Soft blocked: yes" || true)
    [[ "$total" -gt 0 && "$total" -eq "$blocked" ]]
}

token=$(new_click_token airplane)

if is_all_blocked; then
    eww_set airplane_state 0
    log airplane "optimistic=0 (was on, unblocking all)"
    rfkill unblock all
    action_rc=$?
else
    eww_set airplane_state 1
    log airplane "optimistic=1 (was off, blocking all)"
    rfkill block all
    action_rc=$?
fi

sleep 0.3
if is_latest_click airplane "$token"; then
    if is_all_blocked; then
        eww_set airplane_state 1
    else
        eww_set airplane_state 0
    fi
fi
log airplane "confirmed (rfkill exit $action_rc)"
