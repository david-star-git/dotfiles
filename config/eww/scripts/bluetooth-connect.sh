#!/usr/bin/env bash
# bluetooth-connect.sh <mac>
# Pairs (if needed), trusts, and connects. Writes a result the UI polls.
set -uo pipefail

mac="${1:-}"
RESULT_FILE="$HOME/.cache/bluetooth-connect-result"

if [[ -z "$mac" ]]; then
    echo "no device given" > "$RESULT_FILE"
    exit 1
fi

echo "connecting:$mac" > "$RESULT_FILE"

already_paired=$(bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes" && echo yes || echo no)

if [[ "$already_paired" == "no" ]]; then
    bluetoothctl pair "$mac" >/dev/null 2>&1
fi
bluetoothctl trust "$mac" >/dev/null 2>&1
out=$(bluetoothctl connect "$mac" 2>&1)

if grep -qi "Connection successful" <<< "$out" || \
   bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
    echo "connected:$mac" > "$RESULT_FILE"
else
    echo "failed:$mac:$out" > "$RESULT_FILE"
fi
