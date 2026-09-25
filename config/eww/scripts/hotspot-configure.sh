#!/usr/bin/env bash
# hotspot-configure.sh — the Hotspot form's submit button: validates,
# saves the SSID/password, and if the hotspot is currently live,
# restarts it immediately with the new settings. If it's off, the saved
# values just get picked up next time hotspot-toggle.sh turns it on.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

ssid="$(eww get hotspot_ssid_value 2>/dev/null || true)"
password="$(eww get hotspot_password_value 2>/dev/null || true)"

if [[ -z "$ssid" ]]; then
    eww_set hotspot_configure_status "error"
    log hotspot-configure "rejected: empty SSID"
    exit 1
fi
# WPA2 requires an 8+ character password; nmcli will simply fail
# otherwise, so check up front rather than silently doing nothing.
if [[ -n "$password" && ${#password} -lt 8 ]]; then
    eww_set hotspot_configure_status "error"
    log hotspot-configure "rejected: password under 8 characters"
    exit 1
fi

conf="$HOME/.cache/hotspot-config"
printf '%s\n%s\n' "$ssid" "$password" > "$conf"
log hotspot-configure "saved ssid=$ssid"

active_ap_connection() {
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        mode=$(nmcli -g 802-11-wireless.mode connection show "$name" 2>/dev/null)
        [[ "$mode" == "ap" ]] && { echo "$name"; return 0; }
    done < <(nmcli -t -f NAME connection show --active 2>/dev/null)
    return 1
}

current="$(active_ap_connection || true)"
if [[ -n "$current" ]]; then
    log hotspot-configure "hotspot is live — restarting with new settings"
    nmcli connection down "$current" >/dev/null 2>&1
    if [[ -n "$password" ]]; then
        nmcli device wifi hotspot ssid "$ssid" password "$password" >/dev/null 2>&1
    else
        nmcli device wifi hotspot ssid "$ssid" >/dev/null 2>&1
    fi
fi

eww_set hotspot_configure_status "saved"
