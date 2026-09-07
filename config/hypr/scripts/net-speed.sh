#!/usr/bin/env bash
# net-speed.sh — prints "down / up" for the default route interface.
# Computes a delta between two /sys reads one second apart (called once per
# eww poll interval; the 1s sleep happens inside so each invocation is
# self-contained and doesn't need a background daemon). Pure bash integer
# arithmetic — no bc/awk dependency.
set -euo pipefail

iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}') || iface=""

if [[ -z "${iface:-}" ]]; then
    echo "󰲛 --"
    exit 0
fi

rx_path="/sys/class/net/${iface}/statistics/rx_bytes"
tx_path="/sys/class/net/${iface}/statistics/tx_bytes"

[[ -r "$rx_path" && -r "$tx_path" ]] || { echo "󰲛 --"; exit 0; }

rx1=$(<"$rx_path"); tx1=$(<"$tx_path")
sleep 1
rx2=$(<"$rx_path"); tx2=$(<"$tx_path")

fmt() {
    local bytes=$1
    if (( bytes < 1024 )); then
        printf "%dB/s" "$bytes"
    elif (( bytes < 1048576 )); then
        printf "%dKB/s" $(( bytes / 1024 ))
    else
        local whole=$(( bytes / 1048576 ))
        local tenths=$(( (bytes * 10 / 1048576) % 10 ))
        printf "%d.%dMB/s" "$whole" "$tenths"
    fi
}

down=$(( rx2 - rx1 ))
up=$(( tx2 - tx1 ))

echo "󰇚$(fmt "$down") 󰕒$(fmt "$up")"
