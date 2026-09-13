#!/usr/bin/env bash
# airplane-reconcile.sh — periodic drift correction.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

total=$(rfkill list 2>/dev/null | grep -c "^[0-9]" || true)
blocked=$(rfkill list 2>/dev/null | grep -c "Soft blocked: yes" || true)

if [[ "$total" -gt 0 && "$total" -eq "$blocked" ]]; then
    eww_set airplane_state 1
    echo 1
else
    eww_set airplane_state 0
    echo 0
fi
