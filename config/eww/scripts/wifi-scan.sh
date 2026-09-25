#!/usr/bin/env bash
# wifi-scan.sh — prints the visible Wi-Fi networks as a JSON array:
# [{"ssid":"...","signal":73,"secured":true,"active":false}, ...]
#
# nmcli lists one row per BSSID, so the same network can appear several
# times (different access points broadcasting the same SSID); this
# keeps only the strongest reading per SSID and sorts by signal.
#
# Known limitation: nmcli's terse (-t) output escapes a literal ":" in
# a field with "\:", which the naive `awk -F:` split below does not
# unescape. An SSID containing a colon will parse incorrectly. This is
# rare enough in practice to accept for now — flag it if you hit one.
set -uo pipefail

nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null |
awk -F: '
{
    inuse=$1; ssid=$2; signal=$3+0; security=$4
    if (ssid == "") next
    if (!(ssid in maxsig) || signal > maxsig[ssid]) {
        maxsig[ssid] = signal
        sec[ssid] = security
        act[ssid] = (inuse == "*") ? "true" : "false"
    }
}
END {
    for (s in maxsig) {
        secured = (sec[s] == "" || sec[s] == "--") ? "false" : "true"
        printf "%s\x1f%s\x1f%s\x1f%s\n", s, maxsig[s], secured, act[s]
    }
}' | sort -t $'\x1f' -k2,2rn |
jq -R -s '
    split("\n") | map(select(length > 0)) |
    map(split("\u001f")) |
    map({ssid: .[0], signal: (.[1] | tonumber), secured: (.[2] == "true"), active: (.[3] == "true")})
' 2>/dev/null || echo "[]"
