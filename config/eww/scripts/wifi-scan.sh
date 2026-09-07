#!/usr/bin/env bash
# wifi-scan.sh — rescans and prints available networks as a JSON array:
# [{"ssid":"...","signal":73,"secured":true,"active":false}, ...]
# Deduplicated by SSID (nmcli lists one row per BSS/access-point radio,
# strongest kept), sorted strongest-first.
set -euo pipefail

nmcli dev wifi rescan >/dev/null 2>&1 || true
sleep 1

nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | python3 -c '
import sys, json

best = {}
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    # nmcli terse output escapes ":" inside fields as "\:" — split carefully.
    parts = []
    cur = ""
    escaped = False
    for ch in line:
        if escaped:
            cur += ch
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == ":":
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    parts.append(cur)
    if len(parts) < 4:
        continue
    in_use, ssid, signal, security = parts[0], parts[1], parts[2], parts[3]
    if not ssid:
        continue
    try:
        signal = int(signal)
    except ValueError:
        signal = 0
    entry = {
        "ssid": ssid,
        "signal": signal,
        "secured": bool(security.strip()),
        "active": in_use.strip() == "*",
    }
    existing = best.get(ssid)
    if existing is None or signal > existing["signal"]:
        best[ssid] = entry

networks = sorted(best.values(), key=lambda n: (-n["active"], -n["signal"]))
print(json.dumps(networks))
'
