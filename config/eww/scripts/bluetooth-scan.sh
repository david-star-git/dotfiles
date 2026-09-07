#!/usr/bin/env bash
# bluetooth-scan.sh — scans for ~4s and prints nearby devices as JSON:
# [{"mac":"...","name":"...","paired":true,"connected":false}, ...]
# Merges live scan results with already-paired devices (paired devices
# don't always keep advertising, so a plain scan can miss them).
set -euo pipefail

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "[]"
    exit 0
fi

bluetoothctl --timeout 4 scan on >/dev/null 2>&1 || true

python3 -c '
import subprocess, json, re

def run(*args):
    return subprocess.run(["bluetoothctl", *args], capture_output=True, text=True).stdout

devices = {}

# All known devices (paired + previously seen)
for line in run("devices").splitlines():
    m = re.match(r"Device (\S+) (.+)", line)
    if not m:
        continue
    mac, name = m.group(1), m.group(2)
    devices[mac] = {"mac": mac, "name": name, "paired": False, "connected": False}

for mac, dev in devices.items():
    info = run("info", mac)
    dev["paired"] = "Paired: yes" in info
    dev["connected"] = "Connected: yes" in info

result = sorted(devices.values(), key=lambda d: (-d["connected"], -d["paired"], d["name"]))
print(json.dumps(result))
'
