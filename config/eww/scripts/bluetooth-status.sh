#!/usr/bin/env bash
# Prints "Off", "No Devices", or "<Name>" / "N devices" for the top tile subtext.
set -euo pipefail

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "Off"
    exit 0
fi

mapfile -t devices < <(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3-)

case "${#devices[@]}" in
    0) echo "No Devices" ;;
    1) echo "${devices[0]}" ;;
    *) echo "${#devices[@]} devices" ;;
esac
