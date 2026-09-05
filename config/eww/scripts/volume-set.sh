#!/usr/bin/env bash
# Sets the default sink's volume to an absolute percent.
# Usage: volume-set.sh 65
set -euo pipefail
pactl set-sink-volume @DEFAULT_SINK@ "${1}%"
