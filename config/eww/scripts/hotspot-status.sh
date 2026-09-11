#!/usr/bin/env bash
# Prints "Off" or "N connected" for the hotspot tile's sublabel.
set -euo pipefail

if ! nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -qi "^Hotspot:"; then
    echo "Off"
    exit 0
fi

# Count stations associated to the hotspot's AP (best-effort; falls back
# to a plain "On" if the driver doesn't expose station dump via iw).
iface=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: '/^Hotspot:/{print $2; exit}')
if [[ -n "$iface" ]] && command -v iw >/dev/null 2>&1; then
    count=$(iw dev "$iface" station dump 2>/dev/null | grep -c "^Station" || true)
    if [[ "$count" -gt 0 ]]; then
        echo "${count} connected"
        exit 0
    fi
fi
echo "On"
