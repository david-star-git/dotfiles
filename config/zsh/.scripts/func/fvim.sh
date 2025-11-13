#!/bin/bash

fvim() {
    local cwd file
    cwd=$(pwd)
    file=$(fzf --height 60% --layout reverse --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window right:60%:wrap)

    if [ -n "$file" ]; then
        cd "$(dirname "$file")" || return

        if [[ $file == *.py ]]; then
            if [ ! -d "venv" ]; then
                python3 -m venv venv
            fi
            source venv/bin/activate
        fi

        nvim "$(basename "$file")"

        if [[ $file == *.py ]]; then
            deactivate
        fi

        cd "$cwd"
    fi
}
