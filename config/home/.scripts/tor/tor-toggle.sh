#!/usr/bin/env bash
# tor-toggle.sh — turn system-wide Tor transparent routing on or off.
#
# WHAT THIS DOES
#   ON:  every outbound TCP connection gets NAT-REDIRECTed to Tor's TransPort,
#        DNS gets redirected to Tor's DNSPort (so lookups don't leak to your
#        normal resolver), all other UDP is DROPPED (Tor only carries TCP —
#        letting other UDP through would bypass Tor entirely and leak your
#        real IP), and IPv6 is DROPPED outright (this setup doesn't route
#        it, so leaving it up would leak).
#   OFF: all of the above is removed via a dedicated iptables chain, so
#        teardown can't accidentally leave a stray rule behind.
#
# WHAT THIS DOES NOT DO
#   - Protect connections already established before you turned this on.
#   - Stop an application that ignores the system network stack in some
#     unusual way (rare, but not this script's job to catch).
#   - Replace Tails/Whonix if you need a formally audited setup. This is a
#     careful iptables wrapper, not a hardened appliance.
#
# Requires root for iptables — runs via pkexec so the polkit agent prompts
# graphically instead of needing a terminal.
#
# Usage: tor-toggle.sh on|off
set -euo pipefail

TRANS_PORT=9040
DNS_PORT=5353

# RFC1918 + other non-routable ranges — always sent direct, never through
# Tor's TransPort. Keeps your LAN (printers, routers, local servers) reachable.
LAN_NETS=(
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
    172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4
)

STATE_FILE="$HOME/.cache/tor-routing-state"

require_root_script() {
    # The actual iptables work runs as root via pkexec, calling this same
    # script with an internal arg so we don't need a second file on disk.
    pkexec bash "$0" "__root_$1"
}

do_on_as_root() {
    tor_uid=$(id -u tor 2>/dev/null || echo "")
    if [[ -z "$tor_uid" ]]; then
        echo "tor user not found — is the tor package installed?" >&2
        exit 1
    fi

    # Make sure Tor is actually running before we redirect anything to it —
    # redirecting into a dead TransPort would just break the network, not
    # protect it.
    systemctl start tor.service
    for _ in $(seq 1 20); do
        systemctl is-active --quiet tor.service && break
        sleep 0.5
    done
    if ! systemctl is-active --quiet tor.service; then
        echo "tor.service did not start — aborting, no rules applied." >&2
        exit 1
    fi

    # ── filter table: block everything Tor can't carry (fail closed) ────────
    iptables -N TOR_BLOCK 2>/dev/null || iptables -F TOR_BLOCK
    iptables -A TOR_BLOCK -m owner --uid-owner "$tor_uid" -j RETURN
    iptables -A TOR_BLOCK -p udp --dport 53 -j RETURN
    for net in "${LAN_NETS[@]}"; do
        iptables -A TOR_BLOCK -d "$net" -j RETURN
    done
    iptables -A TOR_BLOCK -p udp -j DROP
    iptables -C OUTPUT -j TOR_BLOCK 2>/dev/null || iptables -I OUTPUT -j TOR_BLOCK

    ip6tables -N TOR_BLOCK6 2>/dev/null || iptables -F TOR_BLOCK6 2>/dev/null || true
    ip6tables -F TOR_BLOCK6
    ip6tables -A TOR_BLOCK6 -j DROP
    ip6tables -C OUTPUT -j TOR_BLOCK6 2>/dev/null || ip6tables -I OUTPUT -j TOR_BLOCK6

    # ── nat table: redirect TCP + DNS into Tor ───────────────────────────────
    iptables -t nat -N TOR_TRANS 2>/dev/null || iptables -t nat -F TOR_TRANS
    iptables -t nat -A TOR_TRANS -m owner --uid-owner "$tor_uid" -j RETURN
    for net in "${LAN_NETS[@]}"; do
        iptables -t nat -A TOR_TRANS -p tcp -d "$net" -j RETURN
    done
    iptables -t nat -A TOR_TRANS -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    iptables -t nat -A TOR_TRANS -p tcp --syn -j REDIRECT --to-ports "$TRANS_PORT"
    iptables -t nat -C OUTPUT -j TOR_TRANS 2>/dev/null || iptables -t nat -I OUTPUT -j TOR_TRANS

    echo "on" > "$STATE_FILE"
    notify-send -a "tor" -u normal -i "security-high" "Tor routing" "All traffic now routed through Tor."
}

do_off_as_root() {
    iptables -D OUTPUT -j TOR_BLOCK 2>/dev/null || true
    iptables -F TOR_BLOCK 2>/dev/null || true
    iptables -X TOR_BLOCK 2>/dev/null || true

    ip6tables -D OUTPUT -j TOR_BLOCK6 2>/dev/null || true
    ip6tables -F TOR_BLOCK6 2>/dev/null || true
    ip6tables -X TOR_BLOCK6 2>/dev/null || true

    iptables -t nat -D OUTPUT -j TOR_TRANS 2>/dev/null || true
    iptables -t nat -F TOR_TRANS 2>/dev/null || true
    iptables -t nat -X TOR_TRANS 2>/dev/null || true

    echo "off" > "$STATE_FILE"
    notify-send -a "tor" -u normal -i "security-medium" "Tor routing" "Back to normal routing."
}

case "${1:-}" in
    on)         require_root_script on ;;
    off)        require_root_script off ;;
    __root_on)  do_on_as_root ;;
    __root_off) do_off_as_root ;;
    *)          echo "Usage: $0 on|off" >&2; exit 1 ;;
esac
