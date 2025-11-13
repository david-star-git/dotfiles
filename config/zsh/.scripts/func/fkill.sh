#!/bin/bash

fkill() {
    local pids
    pids=$(ps -f -u "$USER" | sed 1d | fzf --height 60% --layout reverse | awk '{print $2}')
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -9 "$@"
    fi
}
