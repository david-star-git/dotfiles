#!/usr/bin/env bash
# Prints 1 if a hotspot connection is active, 0 otherwise.
set -euo pipefail
if nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -qi "^Hotspot:"; then
    echo 1
else
    echo 0
fi
