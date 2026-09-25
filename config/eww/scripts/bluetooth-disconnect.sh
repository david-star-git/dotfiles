#!/usr/bin/env bash
# bluetooth-disconnect.sh MAC — disconnects without unpairing (stays
# trusted so it can be reconnected with a single tap).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

mac="${1:-}"
[[ -z "$mac" ]] && { log bluetooth-disconnect "no MAC given"; exit 1; }

log bluetooth-disconnect "disconnecting $mac"
bluetoothctl disconnect "$mac" >/dev/null 2>&1

result=$("$(dirname "$0")/bluetooth-scan.sh")
eww_set bluetooth_paired "$result"
