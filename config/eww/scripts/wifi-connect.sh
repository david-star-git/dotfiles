#!/usr/bin/env bash
# wifi-connect.sh SSID — connects to a network. If it's secured, the
# password is read from the wifi_pw_value eww var (set live as the user
# types in the password field) rather than taken as a second argument,
# so special characters in the password never have to survive being
# interpolated into a shell command from the yuck template — only the
# SSID does.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

ssid="${1:-}"
if [[ -z "$ssid" ]]; then
    log wifi-connect "no SSID given"
    exit 1
fi

password="$(eww get wifi_pw_value 2>/dev/null || true)"

eww_set wifi_connect_status "connecting"
log wifi-connect "connecting to $ssid"

out=$(mktemp)
if [[ -n "$password" ]]; then
    nmcli device wifi connect "$ssid" password "$password" >"$out" 2>&1
    rc=$?
else
    nmcli device wifi connect "$ssid" >"$out" 2>&1
    rc=$?
fi

if [[ $rc -eq 0 ]]; then
    eww_set wifi_connect_status "connected"
    eww_set wifi_connecting_ssid ""
    eww_set wifi_pw_value ""
    log wifi-connect "connected to $ssid"
else
    eww_set wifi_connect_status "error"
    log wifi-connect "failed to connect to $ssid: $(cat "$out")"
fi
rm -f "$out"

# Refresh the list so the newly-connected network shows as active
# without waiting for the next 10s poll.
result=$("$(dirname "$0")/wifi-scan.sh")
eww_set wifi_networks "$result"
