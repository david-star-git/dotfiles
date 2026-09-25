#!/usr/bin/env bash
# hotspot-load-config.sh — populates the SSID/password fields from the
# last-saved config when the Hotspot view is opened. Run once on open
# (chained into the tile's onclick), not polled — a repeating poll would
# fight with you actively typing in the field, overwriting it mid-edit.
set -uo pipefail

conf="$HOME/.cache/hotspot-config"
ssid="Hotspot"
password=""
if [[ -f "$conf" ]]; then
    saved_ssid="$(sed -n '1p' "$conf")"
    saved_password="$(sed -n '2p' "$conf")"
    [[ -n "$saved_ssid" ]] && ssid="$saved_ssid"
    password="$saved_password"
fi

eww update hotspot_ssid_value="$ssid" hotspot_password_value="$password" hotspot_configure_status='' >/dev/null 2>&1
