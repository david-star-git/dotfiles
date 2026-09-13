#!/usr/bin/env bash
# Prints "No Devices", "<Name>", or "N devices" for the Bluetooth tile's
# sublabel. On/off itself is governed by rfkill (bluetooth-enabled.sh) —
# this script only reports on connected devices when the radio is on,
# so the two signals don't fight each other.
set -uo pipefail

mapfile -t devices < <(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3-)

case "${#devices[@]}" in
    0) echo "No Devices" ;;
    1) echo "${devices[0]}" ;;
    *) echo "${#devices[@]} devices" ;;
esac
