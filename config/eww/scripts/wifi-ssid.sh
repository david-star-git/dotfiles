#!/usr/bin/env bash
# Prints the SSID of the active Wi-Fi connection, or a fallback label.
set -euo pipefail

if [[ "$(nmcli radio wifi)" != "enabled" ]]; then
    echo "Off"
    exit 0
fi

ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2; exit}')
echo "${ssid:-Not Connected}"
