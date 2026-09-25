#!/usr/bin/env bash
# bluetooth-scan.sh — pushes bluetooth_nearby directly via eww_set, and
# prints the paired-device list as JSON (captured by the defpoll into
# bluetooth_paired). One combined script instead of two separate polls,
# so the scan burst below only runs once per cycle, not twice.
#
# Output shape (each list): [{"mac":"AA:BB:..","name":"..","connected":bool}]
set -uo pipefail
source "$(dirname "$0")/lib.sh"

paired_macs="$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')"

to_json_list() {
    # reads "mac\x1fname\x1fconnected" lines on stdin
    jq -R -s '
        split("\n") | map(select(length > 0)) | map(split("\u001f")) |
        map({mac: .[0], name: .[1], connected: (.[2] == "true")})
    ' 2>/dev/null
}

paired_json="[]"
if [[ -n "$paired_macs" ]]; then
    paired_json="$(
        while read -r mac; do
            [[ -z "$mac" ]] && continue
            info="$(bluetoothctl info "$mac" 2>/dev/null)"
            name="$(echo "$info" | awk -F': ' '/^\tName:/{print $2; exit}')"
            connected="false"
            echo "$info" | grep -q "Connected: yes" && connected="true"
            printf '%s\x1f%s\x1f%s\n' "$mac" "${name:-$mac}" "$connected"
        done <<< "$paired_macs" | to_json_list
    )"
    [[ -z "$paired_json" || "$paired_json" == "null" ]] && paired_json="[]"
fi

# Brief discovery burst for nearby (not-yet-paired) devices.
timeout 4 bluetoothctl scan on >/dev/null 2>&1
all_macs="$(bluetoothctl devices 2>/dev/null | awk '{print $2}')"
nearby_json="$(
    while read -r mac; do
        [[ -z "$mac" ]] && continue
        grep -qx "$mac" <<< "$paired_macs" && continue
        info="$(bluetoothctl info "$mac" 2>/dev/null)"
        name="$(echo "$info" | awk -F': ' '/^\tName:/{print $2; exit}')"
        printf '%s\x1f%s\x1ffalse\n' "$mac" "${name:-$mac}"
    done <<< "$all_macs" | to_json_list
)"
[[ -z "$nearby_json" || "$nearby_json" == "null" ]] && nearby_json="[]"

eww_set bluetooth_nearby "$nearby_json"
echo "$paired_json"
