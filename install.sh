#!/bin/bash

# =============================================================================
# install.sh — dotfiles installer
#
# Pure bash TUI, no external deps (no whiptail/dialog).
# Controls: ↑↓ or j/k to navigate, Space to toggle, Enter to confirm, q quit.
#
# Repo layout this script assumes:
#   config/home/     — dotfiles that live directly in $HOME (.zshrc, .mbsyncrc…)
#   config/nvim/     — goes to ~/.config/nvim
#   config/tmux/     — goes to ~/.config/tmux
#   config/kitty/    — goes to ~/.config/kitty
#   config/neomutt/  — goes to ~/.config/neomutt
#   config/fastfetch/— goes to ~/.config/fastfetch
#   config/theme/    — Kvantum, GTK configs and .themes
#   fonts/           — goes to ~/.fonts
#
# All configs are symlinked, never copied, so the repo is always the source
# of truth. Editing a config file edits the repo directly.
# =============================================================================

# ── Privilege check ───────────────────────────────────────────────────────────
# Never run as root — sudo is called explicitly only where elevated access is
# actually required (pacman, sysctl, ufw, etc.).
if [ "$EUID" -eq 0 ]; then
    echo ""
    echo "  Do NOT run this script as root."
    echo "  Run as a normal user — sudo is used internally where needed."
    echo ""
    exit 1
fi

export ORIGINAL_USER="$USER"
export ORIGINAL_HOME="$HOME"

# Resolve the real path to the repo root, regardless of where the script is
# called from.
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# =============================================================================
# Colors
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
# Renders a navigable checkbox list using only tput + bash builtins.
# No whiptail, dialog, or other external tools required.
#
# Usage:
#   tui_checklist RESULT_VAR "Title" "tag:description:on|off" ...
#
# After the function returns, RESULT_VAR is set to a space-separated string
# of the tags the user left toggled on, e.g. "zsh nvim kitty".

tui_checklist() {
    local result_var="$1"
    local title="$2"
    shift 2
    local -a items=("$@")

    local count=${#items[@]}
    local -a tags descs states

    # Parse each "tag:description:on|off" entry into three parallel arrays.
    for i in "${!items[@]}"; do
        IFS=':' read -r tags[$i] descs[$i] states[$i] <<< "${items[$i]}"
    done

    local cursor=0

    tput civis    # hide cursor while drawing
    tput smcup    # switch to alternate screen buffer (restores terminal on exit)

    # ── Draw function — redraws the entire screen on every keypress ───────────
    _draw() {
        tput clear
        local COLUMNS; COLUMNS=$(tput cols 2>/dev/null || echo 80)
        local width=$(( COLUMNS < 70 ? COLUMNS : 70 ))
        local pad=$(( (width - ${#title} - 4) / 2 ))

        # Centered title box
        printf "\n${BOLD}${FG_CYAN}"
        printf "%${pad}s╔"; printf '═%.0s' $(seq 1 $(( ${#title} + 2 ))); printf "╗\n"
        printf "%${pad}s║ %s ║\n" "" "$title"
        printf "%${pad}s╚"; printf '═%.0s' $(seq 1 $(( ${#title} + 2 ))); printf "╝${RESET}\n\n"

        # Checklist rows
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

        printf "\n${DIM}  ↑↓ navigate   Space toggle   Enter confirm   q quit${RESET}\n"
    }

    # ── Key reader — handles multi-byte escape sequences for arrow keys ───────
    _read_key() {
        local key seq
        IFS= read -rsn1 key
        # Arrow keys send a 3-byte escape sequence: ESC [ A/B/C/D
        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.1 seq
            key="${key}${seq}"
        fi
        printf '%s' "$key"
    }

    # ── Main input loop ───────────────────────────────────────────────────────
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

    # Build result string from all items still toggled on
    local result=""
    for i in "${!tags[@]}"; do
        [[ "${states[$i]}" == "on" ]] && result+="${tags[$i]} "
    done
    printf -v "$result_var" '%s' "${result% }"
}

# =============================================================================
# Utility helpers
# =============================================================================

# --- link ---
# Creates a symlink from src to dest, replacing anything already at dest.
# If src doesn't exist yet it's created as a directory.
link() {
    local src="$1" dest="$2"
    [ ! -e "$src" ] && { warn "Source $src missing — creating."; mkdir -p "$src"; }
    { [ -L "$dest" ] || [ -d "$dest" ] || [ -f "$dest" ]; } && rm -rf "$dest"
    ln -s "$src" "$dest"
    ok "Linked $(basename "$dest") → $src"
}

# --- link_home_files ---
# Links every file and directory inside config/home/ directly into $HOME.
# This handles all dotfiles that live at the root of the home directory
# (.zshrc, .mbsyncrc, .scripts, etc.) without hardcoding each filename.
# Adding a new dotfile to config/home/ is enough — no script changes needed.
link_home_files() {
    local home_config="$SCRIPT_DIR/config/home"
    if [ ! -d "$home_config" ]; then
        warn "config/home/ not found — skipping home dotfile links."
        return
    fi

    info "Linking config/home/* → $ORIGINAL_HOME/..."
    while IFS= read -r -d '' src; do
        local name; name=$(basename "$src")
        link "$src" "$ORIGINAL_HOME/$name"
    done < <(find "$home_config" -maxdepth 1 -mindepth 1 -print0)
}

pacman_install() { sudo pacman -S --noconfirm --needed "$@"; }

ensure_yay() {
    command -v yay &>/dev/null && { ok "yay already installed"; return; }
    info "Installing yay AUR helper..."
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

# --- zsh ---
# Installs zsh and its plugin ecosystem, then links all dotfiles from
# config/home/ into $HOME (which includes .zshrc, .scripts, and anything
# else living there). Sets zsh as the default login shell.
install_zsh() {
    info "Installing zsh..."
    pacman_install zsh zsh-syntax-highlighting zsh-autosuggestions \
        zsh-completions zsh-history-substring-search
    link_home_files
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        ok "Default shell set to zsh (takes effect on next login)"
    fi
    ok "zsh done"
}

# --- nvim ---
# Installs neovim, supporting CLI tools (fzf, ripgrep, etc.), and the
# Packer plugin manager. Runs PackerSync headlessly on first install so
# plugins are ready immediately without manually opening nvim.
install_nvim() {
    info "Installing neovim..."
    pacman_install neovim fzf bat ripgrep eza lazygit wl-clipboard xclip
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/nvim" "$ORIGINAL_HOME/.config/nvim"

    local packer="$ORIGINAL_HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    if [ ! -d "$packer" ]; then
        info "Cloning Packer plugin manager..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer"
        ok "Packer cloned"
    fi

    info "Syncing plugins headlessly — this may take a moment..."
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>/dev/null
    ok "nvim done"
}

# --- tmux ---
# Installs tmux and TPM (Tmux Plugin Manager). Plugins defined in tmux.conf
# are installed on first tmux launch via TPM (Prefix+I to trigger manually).
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
        ok "TPM cloned — press Prefix+I inside tmux to install plugins"
    fi
    ok "tmux done"
}

# --- kitty ---
# Installs kitty terminal emulator and links its config from the repo.
# Kitty reloads config live with Ctrl+Shift+F5 — no restart needed.
# Supports inline images via: kitty +kitten icat <file>
install_kitty() {
    info "Installing kitty..."
    pacman_install kitty
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/kitty" "$ORIGINAL_HOME/.config/kitty"
    ok "kitty done"
}

# =============================================================================
# Mailing list installer — sourced by install.sh
#
# Provides install_mailing_list() which creates the Maildir structure and
# links the neomutt config for a single mailing list.
#
# Usage (in install.sh or called directly):
#   install_mailing_list "AUR"           — sets up ~/Mail/AUR
#   install_mailing_list "OssSecurity"   — sets up ~/Mail/OssSecurity
#   install_mailing_list "Arch"          — sets up ~/Mail/Arch
#
# To add a new mailing list to the system:
#   1. Create config/neomutt/lists/<name>.muttrc in the repo.
#   2. Add a sort_mail rule in config/home/.scripts/mailsort.sh.
#   3. Call install_mailing_list "<name>" from the relevant install block.
#      The name must match the Maildir folder used in mailsort.sh exactly.
# =============================================================================

# --- install_mailing_list ---
# Creates the three standard Maildir subdirectories for a mailing list folder.
# Maildir requires new/, cur/, and tmp/ to exist — without them mbsync and
# neomutt will refuse to use the folder.
#
# This function is idempotent — safe to run multiple times.
install_mailing_list() {
    local name="$1"   # folder name under ~/Mail/, e.g. "AUR"
    local dir="$ORIGINAL_HOME/Mail/$name"

    info "Setting up Maildir for list: $name"
    mkdir -p "$dir"/{new,cur,tmp}
    ok "Maildir created: ~/Mail/$name"
}

# --- install_neomutt (extended version) ---
# Drop this into install.sh in place of the existing install_neomutt().
# Adds list Maildir setup and mailsort installation on top of the base config.
install_neomutt() {
    info "Installing neomutt mail stack..."
    pacman_install neomutt isync msmtp gnupg pass notmuch w3m poppler urlscan

    info "Linking neomutt config..."
    mkdir -p "$ORIGINAL_HOME/.config"
    link "$SCRIPT_DIR/config/neomutt" "$ORIGINAL_HOME/.config/neomutt"

    # .mbsyncrc and other home dotfiles come from config/home/
    link_home_files

    # local.muttrc holds machine-specific settings and is gitignored.
    # Create it empty so neomutt's source directive doesn't error on startup.
    local local_rc="$SCRIPT_DIR/config/neomutt/local.muttrc"
    [ ! -f "$local_rc" ] && { touch "$local_rc"; ok "Created empty local.muttrc"; }

    # Ensure the lists/ directory exists inside the neomutt config so the
    # wildcard source in neomuttrc doesn't produce an error on a fresh install.
    mkdir -p "$SCRIPT_DIR/config/neomutt/lists"

    # ── Mailing list Maildir setup ────────────────────────────────────────────
    # Add a call here for every mailing list you're subscribed to.
    # The folder name must match what mailsort.sh uses in its sort_mail calls.
    install_mailing_list "AUR"
    install_mailing_list "OssSecurity"
    install_mailing_list "Arch"

    # ── mailsort ──────────────────────────────────────────────────────────────
    # mailsort.sh lives in config/home/.scripts/ which link_home_files already
    # symlinks wholesale to ~/.scripts/. No separate link is needed here —
    # just ensure the script is executable in the repo so it works through
    # the symlink.
    chmod +x "$SCRIPT_DIR/config/home/.scripts/mailsort.sh"
    ok "mailsort installed"

    ok "neomutt done"
}

# --- theme ---
# Links Kvantum (Qt theming engine), GTK 3 and GTK 4 themes, the .themes
# directory for window decorations, and the fonts directory. Runs fc-cache
# to register new fonts immediately without a logout.
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

# --- security ---
# Hardens the system in three layers:
#   1. UFW firewall  — deny all inbound by default, allow all outbound
#   2. sysctl        — kernel and network hardening parameters
#   3. Tor           — local SOCKS5 proxy on 127.0.0.1:9050
#
# Also disables services that widen the attack surface unnecessarily:
# avahi (mDNS), cups (printing), bluetooth, sshd.
# Re-enable any of them manually with: sudo systemctl enable --now <name>
install_security() {
    info "Installing security packages..."
    pacman_install ufw tor torsocks
    yay_install aide

    info "Configuring UFW firewall..."
    # Drop all unsolicited inbound connections. Outbound is unrestricted.
    # To open a specific port later: sudo ufw allow 22/tcp
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
    sudo systemctl enable --now ufw
    ok "UFW enabled and set to start on boot"

    info "Disabling unused/risky services..."
    for svc in avahi-daemon cups bluetooth sshd; do
        systemctl is-enabled "$svc" &>/dev/null && \
            sudo systemctl disable --now "$svc" && ok "Disabled $svc"
    done

    info "Applying sysctl hardening..."
    sudo tee /etc/sysctl.d/99-hardening.conf >/dev/null <<'EOF'
# Hide kernel symbol addresses from all users including root
kernel.kptr_restrict = 2
# Restrict dmesg output to root only
kernel.dmesg_restrict = 1
# Reverse path filtering — drop packets whose source has no return route
# through the interface they arrived on (prevents IP spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Reject ICMP redirect messages — prevents route table poisoning
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
# Full address space layout randomization
kernel.randomize_va_space = 2
# Prevent TOCTOU race attacks via hardlinks and symlinks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
    sudo sysctl --system >/dev/null
    ok "sysctl hardening applied"

    info "Configuring Tor..."
    # Local-only SOCKS5 proxy — not exposed to the network.
    # Use: torsocks <command>  or point apps at 127.0.0.1:9050
    sudo tee /etc/tor/torrc >/dev/null <<'EOF'
SocksPort 9050
SocksListenAddress 127.0.0.1
EOF
    ok "Tor configured (start manually: sudo systemctl start tor)"
    ok "security done"
}

# --- fastfetch ---
# Installs fastfetch and links its config directory from the repo.
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

    # Security and neomutt default to off — they need manual configuration
    # after install and can break things if applied blindly on a new machine.
    tui_checklist selected "dotfiles installer" \
        "zsh:zsh + plugins + default shell:on" \
        "nvim:neovim + packer + plugins:on" \
        "tmux:tmux + TPM:on" \
        "kitty:kitty terminal:on" \
        "neomutt:neomutt + full mail stack:off" \
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
