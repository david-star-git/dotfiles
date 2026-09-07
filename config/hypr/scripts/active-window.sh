#!/usr/bin/env bash
# active-window.sh — prints the focused window's app name, mac-menu-bar style.
# Falls back to "Desktop" when nothing is focused (e.g. an empty workspace).
set -euo pipefail

json=$(hyprctl activewindow -j 2>/dev/null)
class=$(jq -r '.class // empty' <<< "$json" 2>/dev/null)

echo "${class:-Desktop}"
