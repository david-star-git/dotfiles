#!/usr/bin/env bash
if eww windows | grep -q '^\*bluetooth-menu'; then
    eww close bluetooth-menu
else
    eww close power-menu wifi-menu audio-menu 2>/dev/null
    eww open bluetooth-menu
fi
