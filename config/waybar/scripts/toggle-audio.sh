#!/usr/bin/env bash
if eww windows | grep -q '^\*audio-menu'; then
    eww close audio-menu
else
    eww close power-menu bluetooth-menu wifi-menu 2>/dev/null
    eww open audio-menu
fi
