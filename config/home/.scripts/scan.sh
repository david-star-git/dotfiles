#!/bin/bash
# scan — network port scanner
#
# Scans a target IP/domain or the entire local subnet for open ports.
# Supports two scan modes:
#   normal  — uses nmap (thorough, all ports)
#   stealth — uses netcat (no nmap required, checks a common port list)
#
# Scanning is parallelised (up to MAX_JOBS concurrent scans) for speed.
# Results can be saved to a file with -S.
#
# Usage:
#   scan -i <IP or domain>   scan a specific target
#   scan -l                  scan the local subnet (auto-detected)
#
# Options:
#   -s, --stealth   use netcat instead of nmap
#   -p <port>       scan only this port
#   -S, --save      save results to a file
#
# Requires: nmap (normal mode) or nc/netcat (stealth mode), nslookup

# ── Colors ────────────────────────────────────────────────────────────────────
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# ── Defaults ──────────────────────────────────────────────────────────────────
STEALTH=0
PORT=""
SAVE=0
TARGET=""
LOCAL_SCAN=0
FOUND_ANY=0
MAX_JOBS=10   # maximum parallel scan jobs

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [-s|--stealth] [-p port] [-S|--save] (-i IP_or_domain | -l)"
    echo -e "  -i IP_or_domain   scan specified IP or domain"
    echo -e "  -l                scan local subnet (auto-detected)"
    echo -e "  -s, --stealth     use netcat instead of nmap"
    echo -e "  -p port           scan only this port"
    echo -e "  -S, --save        save output to a file"
    exit 1
}

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stealth) STEALTH=1;  shift ;;
        -S|--save)    SAVE=1;     shift ;;
        -l)           LOCAL_SCAN=1; shift ;;
        -p)           shift; PORT="$1"; shift ;;
        -i)           shift; TARGET="$1"; shift ;;
        *)            usage ;;
    esac
done

# ── Validation ────────────────────────────────────────────────────────────────
if [[ $LOCAL_SCAN -eq 1 && -n "$TARGET" ]]; then
    echo -e "${RED}[!] Cannot use -i and -l together.${NC}"; usage
fi
if [[ $LOCAL_SCAN -eq 0 && -z "$TARGET" ]]; then
    echo -e "${RED}[!] Either -i or -l must be specified.${NC}"; usage
fi

# ── Dependency checks ─────────────────────────────────────────────────────────
command -v nslookup &>/dev/null || { echo -e "${RED}[!] nslookup not found.${NC}"; exit 1; }
[[ $STEALTH -eq 0 ]] && ! command -v nmap &>/dev/null && { echo -e "${RED}[!] nmap not found.${NC}"; exit 1; }
[[ $STEALTH -eq 1 ]] && ! command -v nc   &>/dev/null && { echo -e "${RED}[!] nc (netcat) not found.${NC}"; exit 1; }

# ── Helper: resolve domain or IP to a list of IPs ────────────────────────────
resolve_ips() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Already an IP — return as-is
        echo "$input"
    else
        # Domain — resolve via nslookup and extract IPv4 addresses
        nslookup "$input" \
            | awk '/^Name:|^Address: /{print $2}' \
            | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
            | sort -u
    fi
}

# ── Helper: detect the local subnet in CIDR notation ─────────────────────────
detect_local_subnet() {
    local subnet=""
    if command -v ip &>/dev/null; then
        subnet=$(ip -4 -o addr show scope global up | awk '{print $4}' | head -n1)
    elif command -v ifconfig &>/dev/null; then
        subnet=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}' | head -n1)
        [[ -n "$subnet" ]] && subnet="${subnet}/24"   # assume /24 if no CIDR available
    fi
    echo "$subnet"
}

# ── Temp files — cleaned up automatically on exit ────────────────────────────
TMP_OUTPUT=$(mktemp)
LOCK_FILE=$(mktemp)
trap 'rm -f "$TMP_OUTPUT" "$LOCK_FILE"' EXIT

# ── Helper: scan a single IP for open ports ───────────────────────────────────
scan_ip() {
    local ip="$1"
    local ports=()

    echo -e "${BLUE}[+] Scanning $ip...${NC}"

    if [[ "$STEALTH" -eq 0 ]]; then
        # nmap mode — scan all ports or the specified one
        if [[ -n "$PORT" ]]; then
            scan_output=$(nmap -Pn -p "$PORT" --open "$ip" 2>/dev/null)
        else
            scan_output=$(nmap -Pn -p- --min-rate=100 --open "$ip")
        fi
        ports=($(echo "$scan_output" | awk '/^[0-9]+\/tcp.*open/{print $1}' | cut -d'/' -f1))
    else
        # stealth mode — probe a fixed list of well-known ports via netcat
        local port_list=()
        if [[ -n "$PORT" ]]; then
            port_list=("$PORT")
        else
            port_list=(20 21 22 23 25 53 69 80 110 139 143 161 443 445 3306 3389 5900 8080 19132 25565)
        fi

        for port in "${port_list[@]}"; do
            nc -z -w1 "$ip" "$port" 2>/dev/null && ports+=("$port")
        done
    fi

    # Print and record each open port
    for port in "${ports[@]}"; do
        port_desc=$(getent services "$port" 2>/dev/null | awk '{print $1}')
        if [[ -n "$port_desc" ]]; then
            echo -e "${GREEN}[✓] Open: ${ip}:${port} (${port_desc})${NC}"
        else
            echo -e "${GREEN}[✓] Open: ${ip}:${port}${NC}"
        fi
        # flock ensures concurrent jobs don't corrupt the output file
        ( flock -x 200; echo "$ip:$port ${port_desc}" >> "$TMP_OUTPUT" ) 200>"$LOCK_FILE"
        FOUND_ANY=1
    done
}

# ── Scan ──────────────────────────────────────────────────────────────────────

if [[ $LOCAL_SCAN -eq 1 ]]; then
    subnet=$(detect_local_subnet)
    [[ -z "$subnet" ]] && { echo -e "${RED}[!] Could not detect local subnet.${NC}"; exit 1; }
    echo -e "${BLUE}[*] Detected local subnet: $subnet${NC}"
    OUTPUT="$HOME/local_network_scan.txt"

    echo -e "${YELLOW}[*] Discovering hosts...${NC}"
    mapfile -t IPS < <(nmap -sn "$subnet" | awk '/Nmap scan report for/{print $NF}' \
        | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    [[ ${#IPS[@]} -eq 0 ]] && { echo -e "${RED}[!] No hosts found.${NC}"; exit 1; }
    echo -e "${YELLOW}[*] Scanning ${#IPS[@]} hosts in parallel...${NC}"
else
    mapfile -t IPS < <(resolve_ips "$TARGET")
    [[ ${#IPS[@]} -eq 0 ]] && { echo -e "${RED}[!] No IPs found for ${TARGET}.${NC}"; exit 1; }
    OUTPUT="$HOME/${TARGET}.txt"
fi

# Launch scan jobs with a concurrency cap of MAX_JOBS
job_count=0
for ip in "${IPS[@]}"; do
    scan_ip "$ip" &
    (( job_count++ ))
    if [[ $job_count -ge $MAX_JOBS ]]; then
        wait -n
        (( job_count-- ))
    fi
done
wait

# ── Output ────────────────────────────────────────────────────────────────────
total_ips=${#IPS[@]}
ips_with_open_ports=$(cut -d: -f1 "$TMP_OUTPUT" 2>/dev/null | sort -u | wc -l || echo 0)
total_open_ports=$(wc -l < "$TMP_OUTPUT" 2>/dev/null || echo 0)

if [[ "$SAVE" -eq 1 ]]; then
    if [[ -s "$TMP_OUTPUT" ]]; then
        mv "$TMP_OUTPUT" "$OUTPUT"
        echo -e "${GREEN}[✓] Results saved to ${OUTPUT}${NC}"
    else
        echo -e "${YELLOW}[!] No open ports found. Nothing saved.${NC}"
    fi
else
    if [[ -s "$TMP_OUTPUT" ]]; then
        echo -e "${GREEN}[✓] Open ports found. Use -S to save results.${NC}"
        cat "$TMP_OUTPUT"
    else
        echo -e "${YELLOW}[!] No open ports found.${NC}"
    fi
fi

echo -e "\n${BLUE}========== SCAN SUMMARY ==========${NC}"
echo -e "${YELLOW} Total IPs scanned     : ${total_ips}${NC}"
echo -e "${GREEN} IPs with open ports   : ${ips_with_open_ports}${NC}"
echo -e "${GREEN} Total open ports found: ${total_open_ports}${NC}"
echo -e "${BLUE}==================================${NC}"
