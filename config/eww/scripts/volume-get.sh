#!/usr/bin/env bash
# Prints the default sink's volume as a bare integer percent.
set -euo pipefail
pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1
