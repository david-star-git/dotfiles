#!/usr/bin/env bash
# restore-av.sh — reapplies the last-saved brightness/volume at session
# start.
#
# brightnessctl/pamixer both reflect live hardware/mixer state, which
# resets to whatever the hardware or driver defaults to on boot —
# independent of eww. The sliders already save every change to
# ~/.cache/saved-brightness and ~/.cache/saved-volume (see the sliders'
# :onchange in control_center.yuck); this is the other half, applying
# those saved values back to the hardware once per session.
#
# This does NOT run automatically — it isn't part of eww's own startup.
# Add one line to your Hyprland config's exec-once so it runs once per
# login, e.g.:
#   exec-once = ~/dotfiles/config/eww/scripts/restore-av.sh
set -uo pipefail

if [[ -f "$HOME/.cache/saved-brightness" ]]; then
    saved="$(cat "$HOME/.cache/saved-brightness")"
    [[ -n "$saved" ]] && brightnessctl set "$saved" >/dev/null 2>&1
fi

if [[ -f "$HOME/.cache/saved-volume" ]]; then
    saved="$(cat "$HOME/.cache/saved-volume")"
    [[ -n "$saved" ]] && pamixer --set-volume "$saved" >/dev/null 2>&1
fi
