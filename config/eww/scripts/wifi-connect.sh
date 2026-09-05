#!/usr/bin/env bash
# wifi-connect.sh <ssid> [password]
# Tries to connect (nmcli reuses a saved profile's password automatically
# if one exists for this SSID — password is only needed for a new network).
# Writes which SSID (if any) just failed to a cache file the UI polls, so
# the one tile that failed can reveal its password field — a plain
# equality check in the UI, no string parsing needed there.
set -uo pipefail

ssid="${1:-}"
password="${2:-}"
FAILED_FILE="$HOME/.cache/wifi-connect-failed-ssid"

if [[ -z "$ssid" ]]; then
    exit 1
fi

: > "$FAILED_FILE"  # clear while attempting

if [[ -n "$password" ]]; then
    nmcli dev wifi connect "$ssid" password "$password" >/dev/null 2>&1
else
    nmcli dev wifi connect "$ssid" >/dev/null 2>&1
fi
rc=$?

if [[ $rc -ne 0 ]]; then
    echo "$ssid" > "$FAILED_FILE"
fi

