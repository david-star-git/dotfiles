#!/usr/bin/env bash
# mail-sync — launch a background tmux window that syncs mail and sorts it
# Called by the neomutt G macro. Runs detached so neomutt stays focused.
# The window closes automatically on success, stays open on error.
tmux new-window -d -n 'mail-sync' \
    'mbsync -a && bash ~/.scripts/mailsort.sh && sleep 1 || { echo; echo "Press any key to close."; read -k1; }'
