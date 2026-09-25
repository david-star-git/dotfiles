#!/usr/bin/env bash
# bluetooth-rescan.sh — the refresh button's action: force a fresh scan
# immediately instead of waiting on the 15s poll.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

eww_set bluetooth_scanning true
result=$("$(dirname "$0")/bluetooth-scan.sh")
eww_set bluetooth_paired "$result"
eww_set bluetooth_scanning false
