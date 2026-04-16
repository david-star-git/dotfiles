#!/usr/bin/env bash
if eww windows | grep -q '^\*wifi-menu'; then
    eww close wifi-menu
else
    eww close power-menu bluetooth-menu audio-menu 2>/dev/null
    eww open wifi-menu
fi
