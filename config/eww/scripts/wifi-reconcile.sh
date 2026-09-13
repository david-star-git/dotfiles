#!/usr/bin/env bash
# wifi-reconcile.sh — run on a defpoll interval. Pushes the real state
# into wifi_state via eww update as a side effect; its own stdout is
# unused (the defpoll exists only to drive this on a timer).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

soft=$(rfkill -J list wlan 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
if [[ "$soft" == "unblocked" ]]; then
    eww_set wifi_state 1
    echo 1
else
    eww_set wifi_state 0
    echo 0
fi
