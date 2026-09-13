#!/usr/bin/env bash
# Prints 1 if the WiFi radio is unblocked (on), 0 if soft/hard-blocked.
# Uses rfkill rather than nmcli — nmcli's D-Bus calls have been
# unreliable from eww's exec context in practice; rfkill talks to the
# kernel directly and has been the one thing that's consistently worked.
set -euo pipefail
soft=$(rfkill -J list wlan 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
[[ "$soft" == "unblocked" ]] && echo 1 || echo 0
