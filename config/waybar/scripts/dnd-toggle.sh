#!/usr/bin/env bash
# Toggle mako's do-not-disturb mode.
if makoctl mode | grep -q 'do-not-disturb'; then
    makoctl mode -r do-not-disturb
else
    makoctl mode -a do-not-disturb
fi
