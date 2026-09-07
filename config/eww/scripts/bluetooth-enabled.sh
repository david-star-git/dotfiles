#!/usr/bin/env bash
# Prints 1 if the Bluetooth radio is powered on, 0 if off.
set -euo pipefail
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo 1
else
    echo 0
fi
