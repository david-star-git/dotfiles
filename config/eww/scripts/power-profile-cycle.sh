#!/usr/bin/env bash
# Cycles performance -> balanced -> power-saver -> performance.
set -euo pipefail

current=$(powerprofilesctl get 2>/dev/null || echo "balanced")

case "$current" in
    performance)  next="balanced" ;;
    balanced)     next="power-saver" ;;
    power-saver)  next="performance" ;;
    *)            next="balanced" ;;
esac

powerprofilesctl set "$next"
