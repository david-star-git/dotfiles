#!/usr/bin/env bash
# Toggles the Wi-Fi radio on/off.
set -euo pipefail
if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
