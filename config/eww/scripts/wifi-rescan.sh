#!/usr/bin/env bash
# wifi-rescan.sh — the refresh button's action: force an actual rescan
# (nmcli's normal list is cached and can be stale for a while) then push
# the updated network list immediately, instead of waiting on the
# regular 10s poll.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

eww_set wifi_scanning true
log wifi-rescan "rescanning"
nmcli device wifi rescan >/dev/null 2>&1
sleep 1.5
result=$("$(dirname "$0")/wifi-scan.sh")
eww_set wifi_networks "$result"
eww_set wifi_scanning false
log wifi-rescan "done"
