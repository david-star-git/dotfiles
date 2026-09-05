#!/usr/bin/env bash
# Prints "87% - 3:42 until full" / "54% - 2:10 remaining" style summary
# using upower. Falls back to a bare percent if upower isn't available.
set -euo pipefail

dev=$(upower -e 2>/dev/null | grep 'BAT' | head -1) || true

if [[ -z "${dev:-}" ]]; then
    echo "No battery"
    exit 0
fi

info=$(upower -i "$dev")
pct=$(grep -oP '(?<=percentage:\s)\d+' <<< "$info" || echo "?")
state=$(grep -oP '(?<=state:\s)\S+' <<< "$info" || echo "")
time_line=$(grep -E "time to (empty|full)" <<< "$info" | sed -E 's/^\s+//')

case "$state" in
    charging)    echo "${pct}% - ${time_line#*: }" ;;
    discharging) echo "${pct}% - ${time_line#*: }" ;;
    *)           echo "${pct}% - ${state}" ;;
esac
