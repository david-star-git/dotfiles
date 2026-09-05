#!/usr/bin/env bash
# Prints current brightness as a bare integer percent.
set -euo pipefail
brightnessctl -m | cut -d, -f4 | tr -d '%'
