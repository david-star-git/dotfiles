#!/usr/bin/env bash
# Prints 1 if the Bluetooth radio is unblocked (on), 0 otherwise.
# rfkill-based, same reasoning as wifi-enabled.sh.
set -euo pipefail
soft=$(rfkill -J list bluetooth 2>/dev/null | jq -r '.rfkilldevices[0].soft // "blocked"')
[[ "$soft" == "unblocked" ]] && echo 1 || echo 0
