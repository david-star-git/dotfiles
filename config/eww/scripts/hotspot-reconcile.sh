#!/usr/bin/env bash
# hotspot-reconcile.sh — periodic drift correction.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

if nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -qi "^Hotspot:"; then
    eww_set hotspot_state 1
    echo 1
else
    eww_set hotspot_state 0
    echo 0
fi
