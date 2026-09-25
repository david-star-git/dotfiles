#!/usr/bin/env bash
# hotspot-clients.sh — lists devices currently associated with the
# hotspot's access point, as JSON: [{"mac":"AA:BB:.."}]
#
# Only the MAC is available this way (via `iw station dump` on the AP's
# interface) — a hostname would need correlating against NetworkManager's
# dnsmasq lease file, whose path varies by distro/NM version, so it's
# left out rather than guessed.
set -uo pipefail

active_ap_iface() {
    local name mode iface
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        mode="$(nmcli -g 802-11-wireless.mode connection show "$name" 2>/dev/null)"
        if [[ "$mode" == "ap" ]]; then
            iface="$(nmcli -g GENERAL.DEVICES connection show "$name" 2>/dev/null | head -1)"
            [[ -n "$iface" ]] && { echo "$iface"; return 0; }
        fi
    done < <(nmcli -t -f NAME connection show --active 2>/dev/null)
    return 1
}

iface="$(active_ap_iface || true)"
if [[ -z "$iface" ]]; then
    echo "[]"
    exit 0
fi

macs="$(iw dev "$iface" station dump 2>/dev/null | awk '/^Station/{print $2}')"
if [[ -z "$macs" ]]; then
    echo "[]"
    exit 0
fi

jq -R -s 'split("\n") | map(select(length > 0)) | map({mac: .})' <<< "$macs" 2>/dev/null || echo "[]"
