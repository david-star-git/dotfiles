#!/usr/bin/env bash
# Prints the active power profile: performance | balanced | power-saver
set -euo pipefail
powerprofilesctl get 2>/dev/null || echo "balanced"
