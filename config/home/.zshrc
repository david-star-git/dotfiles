
# =============================================================================
# ~/.zshrc
# =============================================================================

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# ── Colors ────────────────────────────────────────────────────────────────────
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Colored man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# ── Aliases ───────────────────────────────────────────────────────────────────
export GTK_THEME=catppuccin-mocha-sapphire
alias ls='exa -l'
alias nano='nvim'
alias vim='nvim'

# Prefer ripgrep over grep when available
if command -v rg &>/dev/null; then
    alias grep='rg'
else
    alias grep="/usr/bin/grep --color=auto"
fi

# ── Prompt ────────────────────────────────────────────────────────────────────
# cpu() is defined here rather than in a script because the prompt calls it on
# every command — sourcing or subshelling it each time would be too slow.
cpu() {
    grep 'cpu ' /proc/stat \
        | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' \
        | awk '{printf("%.1f\n", $1)}'
}

autoload -Uz colors && colors
setopt PROMPT_SUBST

setprompt() {
    local LAST_COMMAND=$?
    PROMPT=""

    # Error line — only shown when the last command failed
    if [[ $LAST_COMMAND -ne 0 ]]; then
        PROMPT+="%F{black}(%F{red}ERROR%F{black})-(%F{red}Exit Code ${LAST_COMMAND}%F{black})-(%F{red}"
        case $LAST_COMMAND in
            1)   PROMPT+="General error" ;;
            2)   PROMPT+="Missing keyword, command, or permission problem" ;;
            126) PROMPT+="Permission denied / not executable" ;;
            127) PROMPT+="Command not found" ;;
            128) PROMPT+="Invalid argument to exit" ;;
            129) PROMPT+="Signal 1" ;;
            130) PROMPT+="Interrupted (Ctrl-C)" ;;
            137) PROMPT+="Killed (SIGKILL)" ;;
            *)   PROMPT+="Unknown error" ;;
        esac
        PROMPT+="%F{black})%f"$'\n'
    fi

    PROMPT+=$'\n'

    # User — show hostname when connected over SSH
    if [[ -n "$SSH_CLIENT" ]]; then
        PROMPT+="%F{black}(%F{red}%n@%m"
    else
        PROMPT+="%F{black}(%F{red}%n"
    fi

    # Current directory (one level deep)
    PROMPT+="%F{black}:%F{yellow}%1~%F{black})-"

    # CPU usage, background jobs, open TCP connections
    PROMPT+="(%F{magenta}CPU $(cpu)%%%F{black}:%F{magenta}%j"
    if [[ -r /proc/net/tcp ]]; then
        PROMPT+="%F{black}:%F{magenta}Net $(($(wc -l < /proc/net/tcp)-1))"
    fi
    PROMPT+="%F{black})-"

    # Date and time
    PROMPT+="%F{black}(%F{cyan}%D{%a} %D{%b-%-m} %F{blue}%D{%I:%M:%S%P}%F{black})"

    PROMPT+=$'\n'

    # Green > for user, red > for root
    if [[ $EUID -ne 0 ]]; then
        PROMPT+="%F{green}>%f "
    else
        PROMPT+="%F{red}>%f "
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd setprompt

# ── Script autoloader ─────────────────────────────────────────────────────────
# Three tiers of scripts, each loaded differently:
#
#   .scripts/*.sh        — standalone scripts, aliased by filename so typing
#                          "record" runs bash ~/.scripts/record.sh
#
#   .scripts/shell/*.sh  — scripts that need the current shell environment
#                          (e.g. they use cd). Sourced so changes persist.
#
#   .scripts/func/*.sh   — small helper functions, sourced so they become
#                          shell functions callable without a subshell.

SCRIPT_DIR="$HOME/.scripts"

# func/ — source first so functions are available to everything else
for f in "$SCRIPT_DIR"/func/*.sh; do
    [[ -f "$f" ]] && source "$f"
done

# shell/ — source into current shell (cd and env changes persist)
for f in "$SCRIPT_DIR"/shell/*.sh; do
    [[ -f "$f" ]] || continue
    name="${f:t:r}"
    # wrap in a function so the script only runs when called by name,
    # not on every shell startup
    eval "${name}() { source \"${f}\"; }"
done

# top-level scripts — alias to run via bash
for script in "$SCRIPT_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    name="${script:t:r}"
    alias "$name"="bash \"$script\""
done

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_VERIFY

# ── Plugins ───────────────────────────────────────────────────────────────────
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && {
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
}

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# command-not-found suggestions
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] \
    && source /usr/share/doc/pkgfile/command-not-found.zsh \
    || [[ -f /usr/share/doc/pkgfile/command-not-found.bash ]] \
    && source /usr/share/doc/pkgfile/command-not-found.bash

# ── Path ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

