#!/usr/bin/env bash
# Toggles a NetworkManager-managed WiFi hotspot on/off. Starting it will
# take over your WiFi radio if you only have one adapter — same trade-off
# as toggling Personal Hotspot on any OS with a single radio.
set -euo pipefail

if nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -qi "^Hotspot:"; then
    nmcli connection down Hotspot >/dev/null 2>&1
else
    # nmcli reuses the "Hotspot" connection profile (and its
    # auto-generated SSID/password) if one already exists from a
    # previous run, otherwise creates one.
    nmcli device wifi hotspot >/dev/null 2>&1
fi
