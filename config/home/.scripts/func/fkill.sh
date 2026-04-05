#!/bin/bash
# fkill — fuzzy process killer
# Lists your running processes in fzf. Select one (or more with Tab) and they
# are sent SIGKILL (kill -9). Any extra arguments to fkill are passed through
# to kill, so you can do: fkill -15  to send SIGTERM instead.
# Requires: fzf

fkill() {
    local pids
    # List processes owned by the current user, strip the header line,
    # pipe into fzf for interactive selection, then extract the PID column.
    pids=$(ps -f -u "$USER" | sed 1d | fzf --height 60% --layout reverse | awk '{print $2}')

    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -9 "$@"
    fi
}
