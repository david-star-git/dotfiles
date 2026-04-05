#!/bin/bash

fcd() {
    local directory=$(
        fd --type d | fzf --height 60% --layout reverse --query="$1" --no-multi --select-1 --exit-0 --preview "tree -C {} | head -100"
    )
    if [[ -n $directory ]]; then
        cd "$directory"
    fi
}
