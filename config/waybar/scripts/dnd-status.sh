#!/usr/bin/env bash
# Outputs waybar return-type=json for the custom/dnd module.
if makoctl mode | grep -q 'do-not-disturb'; then
    echo '{"text":"󰂛","tooltip":"Do Not Disturb: On","class":"dnd-on"}'
else
    echo '{"text":"","tooltip":"Do Not Disturb: Off","class":"dnd-off"}'
fi
