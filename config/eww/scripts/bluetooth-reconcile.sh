#!/usr/bin/env bash
# bluetooth-reconcile.sh — periodic drift correction, same pattern as
# wifi-reconcile.sh.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

soft=$(rfkill -J list bluetooth 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
if [[ "$soft" == "unblocked" ]]; then
    eww_set bt_state 1
    echo 1
else
    eww_set bt_state 0
    echo 0
fi
