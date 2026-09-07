#!/usr/bin/env bash
# Sets brightness to an absolute percent. Usage: brightness-set.sh 65
set -euo pipefail
brightnessctl set "${1}%" >/dev/null
