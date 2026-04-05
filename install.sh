#!/bin/bash

# =============================================================================
# install.sh — dotfiles installer
# Pure bash TUI — no whiptail/dialog dependency.
# Arrow keys to move, Space to toggle, Enter to confirm.
# =============================================================================

# ── Privilege check ───────────────────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
    echo ""
    echo "  Do NOT run this script as root."
    echo "  Run as a normal user — sudo is called internally where needed."
    echo ""
    exit 1
fi

export ORIGINAL_USER="$USER"
export ORIGINAL_HOME="$HOME"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# =============================================================================
# Terminal colors
# =============================================================================

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
FG_WHITE="\033[97m"
FG_CYAN="\033[96m"
FG_GREEN="\033[92m"
FG_YELLOW="\033[93m"
FG_RED="\033[91m"
BG_SELECTED="\033[48;5;236m"

ok()   { echo -e "${FG_GREEN}  ✔ $1${RESET}"; }
info() { echo -e "${FG_CYAN}  → $1${RESET}"; }
warn() { echo -e "${FG_YELLOW}  ! $1${RESET}"; }
err()  { echo -e "${FG_RED}  ✘ $1${RESET}"; }

# =============================================================================
# Pure bash TUI checklist
# =============================================================================
# Usage: tui_checklist RESULT_VAR "Title" "tag:desc:on|off" ...
# Sets RESULT_VAR to a space-separated list of selected tags.

tui_checklist() {
    local result_var="$1"
    local title="$2"
    shift 2
    local -a items=("$@")

    local count=${#items[@]}
    local -a tags descs states
    for i in "${!items[@]}"; do
        IFS=':' read -r tags[$i] descs[$i] states[$i] <<< "${items[$i]}"
    done

    local cursor=0

    # Hide cursor and switch to alternate screen buffer
    tput civis
    tput smcup

    _draw() {
        tput clear
        local COLUMNS; COLUMNS=$(tput cols 2>/dev/null || echo 80)
        local width=$(( COLUMNS < 70 ? COLUMNS : 70 ))
        local pad=$(( (width - ${#title} - 4) / 2 ))

        # Header box
        printf "\n${BOLD}${FG_CYAN}"
        printf "%${pad}s╔"; printf '═%.0s' $(seq 1 $(( ${#title} + 2 ))); printf "╗\n"
        printf "%${pad}s║ %s ║\n" "" "$title"
        printf "%${pad}s╚"; printf '═%.0s' $(seq 1 $(( ${#title} + 2 ))); printf "╝${RESET}\n\n"

        # Items
        for i in "${!tags[@]}"; do
            local box="${FG_RED}[ ]${RESET}"
            [[ "${states[$i]}" == "on" ]] && box="${FG_GREEN}[✔]${RESET}"

            if [ "$i" -eq "$cursor" ]; then
                printf "${BG_SELECTED}${BOLD}${FG_WHITE}  ▶ %b  %-14s  %s${RESET}\n" \
                    "$box" "${tags[$i]}" "${descs[$i]}"
            else
                printf "    %b  ${DIM}%-14s  %s${RESET}\n" \
                    "$box" "${tags[$i]}" "${descs[$i]}"
            fi
        done

        # Footer
        printf "\n${DIM}  ↑↓ navigate   Space toggle   Enter confirm   q quit${RESET}\n"
    }

    _read_key() {
        local key seq
        IFS= read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.1 seq
            key="${key}${seq}"
        fi
        printf '%s' "$key"
    }

    while true; do
        _draw
        local key; key=$(_read_key)
        case "$key" in
            $'\x1b[A'|k) (( cursor > 0 )) && (( cursor-- )) ;;
            $'\x1b[B'|j) (( cursor < count - 1 )) && (( cursor++ )) ;;
            ' ')
                [[ "${states[$cursor]}" == "on" ]] \
                    && states[$cursor]="off" \
                    || states[$cursor]="on"
                ;;
            ''|$'\n') break ;;
            q|Q)
                tput rmcup; tput cnorm
                echo ""; echo "  Installation cancelled."; exit 0 ;;
        esac
    done

    tput rmcup
    tput cnorm

    local result=""
    for i in "${!tags[@]}"; do
        [[ "${states[$i]}" == "on" ]] && result+="${tags[$i]} "
    done
    printf -v "$result_var" '%s' "${result% }"
}

# =============================================================================
# Utility helpers
# =============================================================================

link() {
    local src="$1" dest="$2"
    [ ! -e "$src" ] && { warn "Source $src missing — creating."; mkdir -p "$src"; }
    { [ -L "$dest" ] || [ -d "$dest" ] || [ -f "$dest" ]; } && rm -rf "$dest"
    ln -s "$src" "$dest"
    ok "Linked $(basename "$dest") → $src"
}

pacman_install() { sudo pacman -S --noconfirm --needed "$@"; }

ensure_yay() {
    command -v yay &>/dev/null && { ok "yay already installed"; return; }
    info "Installing yay..."
    sudo pacman -Sy --noconfirm base-devel git
    local tmp; tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp"
    pushd "$tmp" >/dev/null; makepkg -si --noconfirm; popd >/dev/null
    rm -rf "$tmp"
    ok "yay installed"
}

yay_install() { ensure_yay; yay -S --noconfirm --needed "$@"; }

# =============================================================================
# Components
# =============================================================================

install_zsh() {
    info "Installing zsh..."
    pacman_install zsh zsh-syntax-highlighting zsh-autosuggestions \
        zsh-completions zsh-history-substring-search
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/home/.zshrc"   "$ORIGINAL_HOME/.zshrc"
    link "$SCRIPT_DIR/config/home/.scripts" "$ORIGINAL_HOME/.scripts"
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        ok "Default shell set to zsh (takes effect on next login)"
    fi
    ok "zsh done"
}

install_nvim() {
    info "Installing neovim..."
    pacman_install neovim fzf bat ripgrep eza lazygit wl-clipboard xclip
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/nvim" "$ORIGINAL_HOME/.config/nvim"

    local packer="$ORIGINAL_HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    if [ ! -d "$packer" ]; then
        info "Cloning Packer..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer"
        ok "Packer cloned"
    fi

    info "Syncing plugins (headless)..."
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>/dev/null
    ok "nvim done"
}

install_tmux() {
    info "Installing tmux..."
    pacman_install tmux
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/tmux" "$ORIGINAL_HOME/.config/tmux"

    local tpm="$ORIGINAL_HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm" ]; then
        info "Cloning TPM..."
        mkdir -p "$ORIGINAL_HOME/.tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$tpm"
        ok "TPM cloned"
    fi
    ok "tmux done"
}

install_kitty() {
    info "Installing kitty..."
    pacman_install kitty
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/kitty" "$ORIGINAL_HOME/.config/kitty"
    ok "kitty done"
}

install_neomutt() {
    info "Installing neomutt mail stack..."
    pacman_install neomutt isync msmtp gnupg pass notmuch w3m poppler urlscan
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/neomutt" "$ORIGINAL_HOME/.config/neomutt"

    # local.muttrc holds machine-specific settings (passwords, local paths).
    # It is intentionally not tracked in git — create it empty if missing.
    local local_rc="$SCRIPT_DIR/config/neomutt/local.muttrc"
    [ ! -f "$local_rc" ] && { touch "$local_rc"; ok "Created empty local.muttrc"; }
    ok "neomutt done"
}

install_theme() {
    info "Installing theme..."
    pacman_install kvantum
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/theme/Kvantum" "$ORIGINAL_HOME/.config/Kvantum"
    link "$SCRIPT_DIR/config/theme/gtk-3.0" "$ORIGINAL_HOME/.config/gtk-3.0"
    link "$SCRIPT_DIR/config/theme/gtk-4.0" "$ORIGINAL_HOME/.config/gtk-4.0"
    link "$SCRIPT_DIR/config/theme/.themes" "$ORIGINAL_HOME/.themes"
    link "$SCRIPT_DIR/fonts"                "$ORIGINAL_HOME/.fonts"
    info "Refreshing font cache..."
    fc-cache -f "$ORIGINAL_HOME/.fonts"
    ok "theme done"
}

install_security() {
    info "Installing security tools..."
    pacman_install ufw tor torsocks
    yay_install aide

    info "Configuring UFW..."
    # Default deny all inbound, allow all outbound.
    # Open specific ports manually as needed (e.g. sudo ufw allow 22/tcp).
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
    sudo systemctl enable --now ufw
    ok "UFW enabled"

    info "Disabling unused services..."
    # These services widen the attack surface — re-enable individually if needed.
    for svc in avahi-daemon cups bluetooth sshd; do
        systemctl is-enabled "$svc" &>/dev/null && \
            sudo systemctl disable --now "$svc" && ok "Disabled $svc"
    done

    info "Applying sysctl hardening..."
    sudo tee /etc/sysctl.d/99-hardening.conf >/dev/null <<'EOF'
# Hide kernel pointers from all users (even root)
kernel.kptr_restrict = 2
# Restrict dmesg to root
kernel.dmesg_restrict = 1
# Reverse path filtering — drops spoofed/asymmetric packets
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Reject ICMP redirects — prevents route table poisoning
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
# Full ASLR — randomize all memory layout
kernel.randomize_va_space = 2
# Prevent hardlink and symlink TOCTOU race attacks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
    sudo sysctl --system >/dev/null
    ok "sysctl hardening applied"

    info "Configuring Tor..."
    # Local-only SOCKS5 proxy on port 9050 — not exposed to the network.
    # Use with: torsocks <command> or configure apps to proxy through 127.0.0.1:9050
    sudo tee /etc/tor/torrc >/dev/null <<'EOF'
SocksPort 9050
SocksListenAddress 127.0.0.1
EOF
    ok "Tor configured (start with: sudo systemctl start tor)"
    ok "security done"
}

install_fastfetch() {
    info "Installing fastfetch..."
    pacman_install fastfetch
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/fastfetch" "$ORIGINAL_HOME/.config/fastfetch"
    ok "fastfetch done"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local selected=""

    tui_checklist selected "dotfiles installer" \
        "zsh:zsh + plugins + default shell:on" \
        "nvim:neovim + packer + plugins:on" \
        "tmux:tmux + TPM:on" \
        "kitty:kitty terminal:on" \
        "neomutt:neomutt + mail stack:off" \
        "theme:Kvantum + GTK + fonts:on" \
        "security:UFW + sysctl + Tor:off" \
        "fastfetch:fastfetch system info:on"

    if [ -z "$selected" ]; then
        echo ""; warn "Nothing selected — nothing to do."; exit 0
    fi

    echo ""
    echo -e "${BOLD}${FG_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  Installing: ${FG_WHITE}$selected${RESET}"
    echo -e "${BOLD}${FG_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    [[ "$selected" == *"zsh"*       ]] && install_zsh
    [[ "$selected" == *"nvim"*      ]] && install_nvim
    [[ "$selected" == *"tmux"*      ]] && install_tmux
    [[ "$selected" == *"kitty"*     ]] && install_kitty
    [[ "$selected" == *"neomutt"*   ]] && install_neomutt
    [[ "$selected" == *"theme"*     ]] && install_theme
    [[ "$selected" == *"security"*  ]] && install_security
    [[ "$selected" == *"fastfetch"* ]] && install_fastfetch

    echo ""
    echo -e "${BOLD}${FG_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    ok "All done! Log out and back in for shell changes to take effect."
    echo -e "${BOLD}${FG_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

main "$@"
