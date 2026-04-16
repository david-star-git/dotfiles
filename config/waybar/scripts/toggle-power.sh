#!/usr/bin/env bash
# Toggle the eww power-menu popup.
# Closes other menus first so only one is ever open.

if eww windows | grep -q '^\*power-menu'; then
    eww close power-menu
else
    eww close bluetooth-menu wifi-menu audio-menu 2>/dev/null
    eww open power-menu
fi
