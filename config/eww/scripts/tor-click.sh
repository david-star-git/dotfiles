#!/usr/bin/env bash
# tor-click.sh — replaces the inline yuck onclick, which had a real bug:
# turning Tor off while it was stuck in "connecting" didn't work because
# the ternary only checked for status=="off" to decide "turn on", but
# never had a robust "force off from any state" path, and pkexec (which
# blocks waiting for a password) could hang the whole thing with nothing
# to time it out.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

current=$(eww get tor_status 2>/dev/null || echo "off")
token=$(new_click_token tor)
log tor "click while status=$current"

if [[ "$current" == "off" ]]; then
    eww_set tor_status connecting
    log tor "requesting on (pkexec, 25s timeout)"
    timeout 25 ~/.scripts/tor/tor-toggle.sh on
    rc=$?
    log tor "on request finished, exit=$rc"
    if [[ $rc -ne 0 ]]; then
        # pkexec was cancelled, timed out, or the on-path failed for any
        # reason — don't leave the tile stuck showing "Connecting…"
        # forever. But only if nothing newer has already superseded this
        # click (e.g. you gave up and clicked it off again yourself
        # during the 25s wait) — otherwise this stale failure would stomp
        # whatever the newer click already set.
        if is_latest_click tor "$token"; then
            eww_set tor_status off
            log tor "on request failed — forced back to off"
        else
            log tor "on request failed, but a newer click already took over — not touching state"
        fi
    fi
    # On success, leave it to the regular tor_status poll to move to
    # "connected" once check.torproject.org actually confirms it.
else
    # From "connecting" OR "connected" — always tear down, no confirmation
    # dialog needed for turning it off.
    eww_set tor_status off
    log tor "requesting off"
    timeout 10 ~/.scripts/tor/tor-toggle.sh off
    rc=$?
    log tor "off request finished, exit=$rc"
fi
