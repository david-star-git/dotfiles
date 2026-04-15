#!/bin/bash
# =============================================================================
# wallpaper.sh — rofi wallpaper switcher
#
# Usage:
#   wallpaper.sh            — open rofi picker, set chosen wallpaper
#   wallpaper.sh --restore  — silently restore last set wallpaper (for autostart)
#
# Dependencies:
#   awww        — animated wallpaper daemon
#   rofi        — picker UI
#
# State file: ~/.cache/hypr/wallpaper
#   Contains the absolute path of the currently active wallpaper.
#   Written on every successful set; read on --restore.
#
# Wallpaper directory: ~/wallpapers/
#   Place any image (png/jpg/jpeg/webp/gif) there — the script finds them all.
# =============================================================================

WALLPAPER_DIR="$(realpath "$HOME/wallpapers")"
STATE_FILE="$HOME/.cache/hypr/wallpaper"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"

# Supported extensions (case-insensitive via find)
EXTS=( png jpg jpeg webp gif )

# ── Helpers ───────────────────────────────────────────────────────────────────

die() { echo "wallpaper.sh: $*" >&2; exit 1; }

# Write chosen path to state file
save_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    printf '%s' "$1" > "$STATE_FILE"
}

# Apply a wallpaper path
apply_wallpaper() {
    local path="$1"
    [ -f "$path" ] || die "File not found: $path"
    awww img "$path" --transition-step 15 --transition-fps 60 --transition-type fade
    save_state "$path"
}

# ── --restore mode (called from autostart.conf) ───────────────────────────────
if [[ "$1" == "--restore" ]]; then
    if [ -f "$STATE_FILE" ]; then
        saved=$(cat "$STATE_FILE")
        if [ -f "$saved" ]; then
            apply_wallpaper "$saved"
            exit 0
        fi
    fi
    # No saved wallpaper — set the first one found as a fallback
    fallback=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
           -o -iname "*.webp" -o -iname "*.gif" \) \
        | sort | head -1)
    [ -n "$fallback" ] && apply_wallpaper "$fallback"
    exit 0
fi

# ── Interactive picker ────────────────────────────────────────────────────────

[ -d "$WALLPAPER_DIR" ] || die "Wallpaper directory not found: $WALLPAPER_DIR"

# Build list of wallpaper filenames (relative — displayed in rofi)
mapfile -t files < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
       -o -iname "*.webp" -o -iname "*.gif" \) \
    | sort | xargs -I{} basename {})

[ ${#files[@]} -gt 0 ] || die "No wallpapers found in $WALLPAPER_DIR"

# If a wallpaper is currently active, pre-select it in the list
current_name=""
if [ -f "$STATE_FILE" ]; then
    current_name=$(basename "$(cat "$STATE_FILE")")
fi

# Feed filenames to rofi; -selected-row highlights the current wallpaper
selected_row=0
for i in "${!files[@]}"; do
    [[ "${files[$i]}" == "$current_name" ]] && selected_row=$i && break
done

chosen=$(printf '%s\n' "${files[@]}" | rofi \
    -dmenu \
    -p "Wallpaper" \
    -no-default-config \
    -config "$ROFI_THEME" \
    -selected-row "$selected_row" \
    -format s)

[ -z "$chosen" ] && exit 0   # user cancelled

apply_wallpaper "$WALLPAPER_DIR/$chosen"
