#!/usr/bin/env bash
# tor-status.sh — prints "off" | "connecting" | "connected".
#
# "connecting" means the iptables rules are up but we haven't yet confirmed
# real traffic is going through Tor. "connected" means an actual request
# through the redirected path came back from check.torproject.org saying
# IsTor:true — the distinction the quick-settings tile and the purple
# active-window border key off of, so "purple" only ever means "verified",
# never just "toggled on".
set -euo pipefail

STATE_FILE="$HOME/.cache/tor-routing-state"
LAST_STATUS_FILE="$HOME/.cache/tor-status-last"

state=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

if [[ "$state" != "on" ]]; then
    status="off"
else
    # Real verification: does check.torproject.org see us as Tor?
    # Short timeout — this runs on every poll, must not hang the bar.
    if response=$(curl -s --max-time 4 https://check.torproject.org/api/ip 2>/dev/null); then
        if grep -q '"IsTor":true' <<< "$response"; then
            status="connected"
        else
            status="connecting"
        fi
    else
        status="connecting"
    fi
fi

# Side effect: flip the active-window border to systemPurple only on a
# verified connection, back to the normal accent otherwise. Only fires on
# an actual state change so this doesn't spam hyprctl every poll.
last=$(cat "$LAST_STATUS_FILE" 2>/dev/null || echo "")
if [[ "$status" != "$last" ]]; then
    if [[ "$status" == "connected" ]]; then
        hyprctl keyword general:col.active_border "rgb(bf5af2)" >/dev/null 2>&1 || true
    else
        hyprctl keyword general:col.active_border "rgb(30d158)" >/dev/null 2>&1 || true
    fi
    echo "$status" > "$LAST_STATUS_FILE"
fi

echo "$status"
