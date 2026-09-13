#!/usr/bin/env bash
# Prints "Off" or "N connected" for the hotspot tile's sublabel.
# Finds the AP-mode connection dynamically — see hotspot-toggle.sh for why.
set -uo pipefail

active_ap_connection() {
    local name mode
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        mode=$(nmcli -g 802-11-wireless.mode connection show "$name" 2>/dev/null)
        [[ "$mode" == "ap" ]] && { echo "$name"; return 0; }
    done < <(nmcli -t -f NAME connection show --active 2>/dev/null)
    return 1
}

conn=$(active_ap_connection || true)
if [[ -z "$conn" ]]; then
    echo "Off"
    exit 0
fi

iface=$(nmcli -g GENERAL.DEVICES connection show "$conn" 2>/dev/null)
if [[ -n "$iface" ]] && command -v iw >/dev/null 2>&1; then
    count=$(iw dev "$iface" station dump 2>/dev/null | grep -c "^Station" || true)
    if [[ "$count" -gt 0 ]]; then
        echo "${count} connected"
        exit 0
    fi
fi
echo "On"
