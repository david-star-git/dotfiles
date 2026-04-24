#!/usr/bin/env bash
# =============================================================================
# mailsort — sort incoming mail into per-list Maildir folders
#
# Run automatically after mbsync via the neomutt G macro. Checks every new
# message in INBOX/new/ and INBOX/cur/ for mailing list headers, then moves
# matching messages into their dedicated Maildir folders.
#
# Adding a new mailing list:
#   1. Add a rule block below (copy an existing one and adjust the values).
#   2. Create the Maildir structure:
#        mkdir -p ~/Mail/<FolderName>/{new,cur,tmp}
#   3. Add a corresponding lists/*.muttrc in the neomutt config.
#   4. Register the folder in the installer (see install_mailing_list()).
#
# Rules are matched against the To:, Cc:, and List-Id: headers in order.
# The first match wins — a message is never moved twice.
# =============================================================================
MAIL_DIR="$HOME/Mail"
INBOX="$MAIL_DIR/INBOX"
# ── Colors for terminal output ─────────────────────────────────────────────────
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"
moved=0
checked=0
# =============================================================================
# maildir_move <src_file> <dest_dir>
#
# Moves a Maildir message file into <dest_dir>, stripping any mbsync UID
# tag (,U=NNN) from the filename first.
#
# mbsync embeds the folder-local UID into the filename as ,U=NNN. If we move
# a file from INBOX into another folder without stripping this tag, mbsync
# sees a UID that belongs to a different folder's sequence and throws:
#   "UID NNN is beyond highest assigned UID NNN"
# Stripping ,U=NNN forces mbsync to assign a fresh UID on the next sync.
# =============================================================================
maildir_move() {
    local src="$1"
    local dest_dir="$2"
    local basename
    basename=$(basename "$src")
    # Strip mbsync's UID annotation: ,U=<digits> anywhere in the filename
    local newname="${basename//,U=[0-9]*/}"
    # If the strip produced an empty or identical name, generate a safe unique one
    if [[ -z "$newname" || "$newname" == "$basename" && -e "$dest_dir/$newname" ]]; then
        newname="${basename%%,U=*}.$RANDOM"
    fi
    mv "$src" "$dest_dir/$newname"
}
# =============================================================================
# sort_mail <folder> <header_pattern>
#
# Scans every message in INBOX/new/ and INBOX/cur/ and moves it to <folder>
# if any header in the message matches <header_pattern> (a grep -Ei pattern).
#
# <folder> must be a valid Maildir under ~/Mail/ — the new/ subdirectory
# is used as the destination so the MUA sees the message as new.
# =============================================================================
sort_mail() {
    local folder="$1"       # destination folder name, e.g. "AUR" or "OssSecurity"
    local pattern="$2"      # grep -Ei pattern matched against message headers
    local dest="$MAIL_DIR/$folder/new"
    # Create the Maildir structure if it doesn't exist yet.
    mkdir -p "$MAIL_DIR/$folder"/{new,cur,tmp}
    # Check both new/ (unseen) and cur/ (previously seen but still in INBOX)
    for subdir in new cur; do
        local src="$INBOX/$subdir"
        [[ -d "$src" ]] || continue
        for msg in "$src"/*; do
            [[ -f "$msg" ]] || continue
            (( checked++ ))
            # Read only the headers — stop at the first blank line.
            local headers
            headers=$(awk '/^$/{exit} {print}' "$msg")
            if echo "$headers" | grep -Eiq "$pattern"; then
                maildir_move "$msg" "$dest"
                echo -e "${GREEN}  → $(basename "$msg")${NC} ${BLUE}[$folder]${NC}"
                (( moved++ ))
            fi
        done
    done
}
# =============================================================================
# Mailing list rules
# =============================================================================

# AUR requests — aur-general-request and aur-dev-request
sort_mail "AUR" \
    "^(To|Cc):.*aur-(general|dev)-request@lists\.archlinux\.org|^List-Id:.*aur-(general|dev)-request"

# Arch Linux requests — arch-security-request and pacman-dev-request
sort_mail "Arch" \
    "^(To|Cc):.*(arch-security-request|pacman-dev-request)@lists\.archlinux\.org|^List-Id:.*(arch-security-request|pacman-dev-request)"

# oss-security — sent directly to your address from the openwall list
sort_mail "OssSecurity" \
    "^(To|Cc):.*oss-security|^List-Id:.*lists\.openwall\.com|^From:.*oss-security"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BLUE}mailsort:${NC} checked ${checked} messages, moved ${moved} to list folders."
