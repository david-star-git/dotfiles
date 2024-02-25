# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export EDITOR=nvim
export VISUAL=nvim
export LC_ALL=en_US.UTF-8
export WINIT_X11_SCALE_FACTOR=0.8 alacritty

HISTFILE=$HOME/.zsh_history
setopt appendhistory
setopt SHARE_HISTORY
HISTFILESIZE=10000
HISTSIZE=10000
setopt INC_APPEND_HISTORY
HISTTIMEFORMAT="[%F %T] "
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY

eval $(thefuck --alias)

alias vim='nvim'
alias grep='grep --color=auto'
alias ls='exa -alh'
alias tree='exa --tree'
alias zrc="$EDITOR $HOME/.zshrc"
alias cat="bat"
alias top="btm"
alias neofetch="neofetch --ascii ~/.config/neofetch/cat.txt"
alias battery="acpi -V"
alias batt="acpi"

print ""
print ""
neofetch
print ""

cd

source .config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source .config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
source .config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme


autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9e9e9e,bg=3d3d3d"

bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
