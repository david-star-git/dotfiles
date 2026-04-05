#!/bin/bash
# fcd — fuzzy cd
# Interactively find a directory using fzf and cd into it.
# Uses fd for fast directory listing and tree for the preview pane.
# Optional first argument pre-fills the fzf search query.
# Requires: fd, fzf, tree

fcd() {
    local directory=$(
        fd --type d | fzf \
            --height 60% \
            --layout reverse \
            --query="$1" \
            --no-multi \
            --select-1 \
            --exit-0 \
            --preview "tree -C {} | head -100"
    )
    # Only cd if the user actually selected something (didn't press Esc)
    if [[ -n $directory ]]; then
        cd "$directory"
    fi
}
