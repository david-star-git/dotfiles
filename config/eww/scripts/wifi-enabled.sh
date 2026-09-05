#!/usr/bin/env bash
# Prints 1 if the Wi-Fi radio is on, 0 if off.
set -euo pipefail
[[ "$(nmcli radio wifi)" == "enabled" ]] && echo 1 || echo 0
