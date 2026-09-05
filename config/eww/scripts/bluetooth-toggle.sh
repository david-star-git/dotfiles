#!/usr/bin/env bash
# Toggles the Bluetooth radio on/off.
set -euo pipefail
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off >/dev/null
else
    bluetoothctl power on >/dev/null
fi
