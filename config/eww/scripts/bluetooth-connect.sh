#!/usr/bin/env bash
# bluetooth-connect.sh MAC — trusts, pairs (if needed), and connects.
# Safe to call on an already-paired device too (trust/pair on an
# already-trusted/paired device is a no-op in bluetoothctl).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

mac="${1:-}"
[[ -z "$mac" ]] && { log bluetooth-connect "no MAC given"; exit 1; }

log bluetooth-connect "connecting to $mac"
bluetoothctl trust "$mac" >/dev/null 2>&1
bluetoothctl pair "$mac" >/dev/null 2>&1
bluetoothctl connect "$mac" >/dev/null 2>&1
rc=$?
log bluetooth-connect "connect exit=$rc"

result=$("$(dirname "$0")/bluetooth-scan.sh")
eww_set bluetooth_paired "$result"
