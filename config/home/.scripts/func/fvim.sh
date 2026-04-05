#!/bin/bash
# fvim — fuzzy open in nvim
# Pick any file in the current tree using fzf with a bat syntax-highlighted
# preview, then open it in nvim.
#
# Python files get special treatment:
#   - a venv is created in the file's directory if one doesn't exist yet
#   - the venv is activated before nvim opens and deactivated when nvim exits
#
# After nvim closes the shell is returned to the original directory.
# Requires: fzf, bat, nvim

fvim() {
    local cwd file
    cwd=$(pwd)

    # Pick a file — bat provides the syntax-highlighted preview on the right
    file=$(fzf \
        --height 60% \
        --layout reverse \
        --preview 'bat --style=numbers --color=always --line-range :500 {}' \
        --preview-window right:60%:wrap)

    [[ -z "$file" ]] && return   # user cancelled

    # Move into the file's directory so nvim's relative paths work correctly
    cd "$(dirname "$file")" || return

    # Python: ensure a venv exists and activate it before editing
    if [[ $file == *.py ]]; then
        [[ ! -d "venv" ]] && python3 -m venv venv
        source venv/bin/activate
    fi

    nvim "$(basename "$file")"

    # Python: deactivate venv after nvim exits
    [[ $file == *.py ]] && deactivate

    # Return to the directory we started in
    cd "$cwd"
}
