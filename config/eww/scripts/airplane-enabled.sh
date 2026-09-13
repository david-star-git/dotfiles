#!/usr/bin/env bash
# Prints 1 if every rfkill radio is soft-blocked (airplane mode on), 0
# otherwise. "On" means ALL listed devices are blocked, not just some.
set -euo pipefail

if ! command -v rfkill >/dev/null 2>&1; then
    echo 0
    exit 0
fi

total=$(rfkill list 2>/dev/null | grep -c "^[0-9]" || true)
blocked=$(rfkill list 2>/dev/null | grep -c "Soft blocked: yes" || true)

if [[ "$total" -gt 0 && "$total" -eq "$blocked" ]]; then
    echo 1
else
    echo 0
fi
