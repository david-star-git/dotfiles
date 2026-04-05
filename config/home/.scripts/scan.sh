#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m" # No Color

STEALTH=0
PORT=""
SAVE=0
TARGET=""
LOCAL_SCAN=0
FOUND_ANY=0
MAX_JOBS=10

usage() {
  echo -e "${YELLOW}Usage:${NC} $0 [-s|--stealth] [-p port] [-S|--save] (-i IP_or_domain | -l)"
  echo -e "  -i IP_or_domain : Scan specified IP or domain"
  echo -e "  -l              : Scan local subnet (auto-detected)"
  echo -e "  -s, --stealth   : Use netcat instead of nmap"
  echo -e "  -p port         : Scan only this port"
  echo -e "  -S, --save      : Save output to file"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--stealth)
      STEALTH=1
      shift
      ;;
    -p)
      shift
      PORT="$1"
      shift
      ;;
    -S|--save)
      SAVE=1
      shift
      ;;
    -i)
      shift
      TARGET="$1"
      shift
      ;;
    -l)
      LOCAL_SCAN=1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# Validate args
if [[ $LOCAL_SCAN -eq 1 && -n "$TARGET" ]]; then
  echo -e "${RED}[!] You cannot use -i and -l together.${NC}"
  usage
fi

if [[ $LOCAL_SCAN -eq 0 && -z "$TARGET" ]]; then
  echo -e "${RED}[!] Either -i or -l must be specified.${NC}"
  usage
fi

# Dependency check
if ! command -v nslookup &>/dev/null; then
  echo -e "${RED}[!] 'nslookup' is not installed.${NC} Install it and try again."
  exit 1
fi

if [[ "$STEALTH" -eq 0 && ! $(command -v nmap) ]]; then
  echo -e "${RED}[!] 'nmap' is not installed.${NC} Install it and try again."
  exit 1
fi

if [[ "$STEALTH" -eq 1 && ! $(command -v nc) ]]; then
  echo -e "${RED}[!] 'nc' (netcat) is not installed.${NC} Install it and try again."
  exit 1
fi

# Function to resolve IPs from domain or IP input
resolve_ips() {
  local input="$1"
  # If it looks like an IP, just return it
  if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$input"
  else
    nslookup "$input" | awk '/^Name:|^Address: /{print $2}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
  fi
}

# Function to detect local subnet in CIDR notation
detect_local_subnet() {
  local subnet=""
  if command -v ip &>/dev/null; then
    # Try to get subnet from ip command
    subnet=$(ip -4 -o addr show scope global up | awk '{print $4}' | head -n1)
  elif command -v ifconfig &>/dev/null; then
    # fallback for ifconfig
    subnet=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}' | head -n1)
    if [[ -n "$subnet" ]]; then
      # guess /24 if no CIDR
      subnet="${subnet}/24"
    fi
  fi
  echo "$subnet"
}

OUTPUT=""
TMP_OUTPUT=$(mktemp)
LOCK_FILE=$(mktemp)

trap 'rm -f "$TMP_OUTPUT" "$LOCK_FILE"' EXIT

scan_ip() {
  local ip="$1"
  local ports=()

  echo -e "${BLUE}[+] Scanning $ip...${NC}"

  if [[ "$STEALTH" -eq 0 ]]; then
    if [[ -n "$PORT" ]]; then
      scan_output=$(nmap -Pn -p "$PORT" --open "$ip" 2>/dev/null)
    else
      scan_output=$(nmap -Pn -p- --min-rate=100 --open "$ip")
    fi
    ports=($(echo "$scan_output" | awk '/^[0-9]+\/tcp.*open/{print $1}' | cut -d'/' -f1))
  else
    local port_list=()
    if [[ -n "$PORT" ]]; then
      port_list=("$PORT")
    else
      port_list=(25 23 22 21 20 80 443 25565 19132 8080 53 69 110 139 143 161 445 3389 5900 3306)
    fi

    for port in "${port_list[@]}"; do
      if nc -z -w1 "$ip" "$port" 2>/dev/null; then
        ports+=("$port")
      fi
    done
  fi

  for port in "${ports[@]}"; do
    port_desc=$(getent services "$port" 2>/dev/null | awk '{print $1}')
    if [[ -n "$port_desc" ]]; then
      echo -e "${GREEN}[✓] Open: ${ip}:${port} (${port_desc})${NC}"
    else
      echo -e "${GREEN}[✓] Open: ${ip}:${port}${NC}"
    fi
    (
      flock -x 200
      echo "$ip:$port ${port_desc}" >> "$TMP_OUTPUT"
    ) 200>"$LOCK_FILE"
    FOUND_ANY=1
  done
}

if [[ $LOCAL_SCAN -eq 1 ]]; then
  subnet=$(detect_local_subnet)
  if [[ -z "$subnet" ]]; then
    echo -e "${RED}[!] Could not detect local subnet.${NC}"
    exit 1
  fi
  echo -e "${BLUE}[*] Detected local subnet: $subnet${NC}"
  OUTPUT="$HOME/local_network_scan.txt"

  # Get all hosts in subnet using nmap ping scan (no port scan)
  echo -e "${YELLOW}[*] Discovering hosts in local subnet...${NC}"
  mapfile -t IPS < <(nmap -sn "$subnet" | awk '/Nmap scan report for/{print $NF}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

  if [[ ${#IPS[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No hosts found on local network.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}[*] Parallel scanning ${#IPS[@]} hosts...${NC}"

  job_count=0

  for ip in "${IPS[@]}"; do
    scan_ip "$ip" &

    ((job_count++))
    if [[ $job_count -ge $MAX_JOBS ]]; then
      wait -n
      ((job_count--))
    fi
  done

  wait
  LOCAL_SCAN_DONE=1

else
  # Resolve IPs from domain or IP
  mapfile -t IPS < <(resolve_ips "$TARGET")

  if [[ ${#IPS[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No IPs found for ${TARGET}${NC}"
    exit 1
  fi
  OUTPUT="$HOME/${TARGET}.txt"
fi

# Only scan if not already done in local scan block
if [[ $LOCAL_SCAN_DONE != 1 ]]; then
  job_count=0

  for ip in "${IPS[@]}"; do
    scan_ip "$ip" &

    ((job_count++))
    if [[ $job_count -ge $MAX_JOBS ]]; then
      wait -n
      ((job_count--))
    fi
  done

  wait
fi

# Count summary info
total_ips=${#IPS[@]}
ips_with_open_ports=$(cut -d: -f1 "$TMP_OUTPUT" 2>/dev/null | sort -u | wc -l || echo 0)
total_open_ports=$(wc -l < "$TMP_OUTPUT" 2>/dev/null || echo 0)

if [[ "$SAVE" -eq 1 ]]; then
  if [[ -s "$TMP_OUTPUT" ]]; then
    mv "$TMP_OUTPUT" "$OUTPUT"
    echo -e "${GREEN}[✓] Done.${NC} Results saved to ${OUTPUT}"
  else
    echo -e "${YELLOW}[!] No open ports found.${NC} Nothing saved."
  fi
else
  if [[ -s "$TMP_OUTPUT" ]]; then
    echo -e "${GREEN}[✓] Open ports found, but not saved. Use -S to save results.${NC}"
    cat "$TMP_OUTPUT"
  else
    echo -e "${YELLOW}[!] No open ports found.${NC}"
  fi
fi

# Show summary regardless of save flag
echo -e "\n${BLUE}========== SCAN SUMMARY ==========${NC}"
echo -e "${YELLOW} Total IPs scanned     : ${total_ips}${NC}"
echo -e "${GREEN} IPs with open ports   : ${ips_with_open_ports}${NC}"
echo -e "${GREEN} Total open ports found: ${total_open_ports}${NC}"
echo -e "${BLUE}==================================${NC}"
