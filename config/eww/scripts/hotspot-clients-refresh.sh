#!/usr/bin/env bash
# hotspot-clients-refresh.sh — the refresh button's action.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

eww_set hotspot_scanning true
result=$("$(dirname "$0")/hotspot-clients.sh")
eww_set hotspot_clients "$result"
eww_set hotspot_scanning false
