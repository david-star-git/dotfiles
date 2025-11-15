#!/bin/bash

# =====================================================
# 🧠  Privilege Handling (Run Once as Root)
# =====================================================

# --- Preserve original user info, even if started as root ---
if [ "$EUID" -ne 0 ]; then
    # Not root → store current user and home, then elevate
    export ORIGINAL_USER="$USER"
    export ORIGINAL_HOME="$HOME"
    echo "🔐 Elevating privileges (you'll be asked for your password once)..."
    exec sudo -E bash "$0" "$@"
else
    # Already root → if variables not set, guess the invoking user
    if [ -z "$ORIGINAL_USER" ]; then
        # Detect user who ran sudo or root manually
        if [ -n "$SUDO_USER" ]; then
            export ORIGINAL_USER="$SUDO_USER"
            export ORIGINAL_HOME=$(eval echo "~$SUDO_USER")
        else
            echo -e "\n🚫 Please do NOT run this script directly as root."
            echo "   Run it as a normal user — it will ask for sudo when needed."
            sleep 2
            exit 1
        fi
    fi
fi

# --- Source Script Directory ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# =====================================
# 🚀 Interactive Setup (One-Time Prompts)
# =====================================

# --- Ask All Questions First ---
# Collects the user's choices up front, then runs everything unattended.

echo "=== Setup Options ==="
read -rp "Install security systems? [Y/n] " install_security
read -rp "Install zsh shell? [Y/n] " install_zsh
read -rp "Install i3 window manager? [Y/n] " install_i3
read -rp "Install theme? [Y/n] " install_theme
echo

# Normalize answers (empty → yes)
normalize() {
    [[ "$1" =~ ^[Yy]$ || -z "$1" ]]
}

# =====================================
# ⚙️  Utility Functions for Setup Tasks
# =====================================

# --- Ensure yay Exists ---
# Checks if the 'yay' AUR helper is installed.
# If missing, installs it using pacman and git.
ensure_yay() {
    if ! command -v yay &>/dev/null; then
        echo "⚙️ yay not found. Installing..."
        sudo pacman -Sy --noconfirm base-devel git
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir" && cd "$tmpdir"
        makepkg -si --noconfirm
        cd - >/dev/null
        rm -rf "$tmpdir"
        echo "✅ yay installed successfully"
    fi
}

# --- Package Installation ---
# Installs one or more packages.
# Automatically uses pacman for official repos and yay for AUR packages.
install_pkg() {
    ensure_yay

    for pkg in "$@"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            echo "📦 Installing $pkg..."
            if pacman -Si "$pkg" &>/dev/null; then
                sudo pacman -S --noconfirm "$pkg"
            else
                yay -S --noconfirm "$pkg"
            fi
        else
            echo "✅ $pkg already installed"
        fi
    done
}

# --- Symlink Creation ---
# Creates a symbolic link safely.
# If the destination already exists (file, directory, or symlink),
# it is removed and replaced with a new link.
link() {
    local src=$1
    local dest=$2

    if [ -L "$dest" ] || [ -d "$dest" ] || [ -f "$dest" ]; then
        echo "Replacing $dest"
        rm -rf "$dest"
    fi

    ln -s "$src" "$dest"
    echo "Linked $dest → $src"
}

# =====================================
# 🛡️  System Security & Hardening Setup
# =====================================

setup_security() {
    # --- Package Installation ---
    # Installs hardened kernel, firewall, AppArmor, and security tools.
    install_pkg linux-hardened apparmor ufw dnscrypt-proxy tor torsocks bleachbit aide clamav rkhunter lynis firejail bubblewrap

    # --- UFW Firewall Configuration ---
    # Default deny all incoming traffic, allow all outgoing.
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable

    # --- Enable Security Services ---
    # Automatically start and enable key protection services.
    sudo systemctl enable ufw --now
    sudo systemctl enable apparmor --now
    sudo systemctl enable dnscrypt-proxy --now
    sudo systemctl enable clamav-freshclam --now
    sudo systemctl enable clamav-daemon --now

    # --- Disable Unused / Risky Services ---
    # Minimizes the attack surface by stopping unneeded daemons.
    sudo systemctl disable --now avahi-daemon
    sudo systemctl disable --now cups
    sudo systemctl disable --now bluetooth
    sudo systemctl disable --now sshd

    # --- AIDE (Integrity Checking) ---
    # Initializes and sets up the AIDE database.
    sudo aide --init
    sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

    # --- Sysctl Hardening ---
    # Kernel and network-level hardening parameters.
    sudo tee /etc/sysctl.d/99-sysctl.conf > /dev/null <<'EOF'
    # System hardening settings
    kernel.kptr_restrict = 2
    kernel.dmesg_restrict = 1
    net.ipv4.conf.all.rp_filter = 1
    net.ipv4.conf.default.rp_filter = 1
    net.ipv4.conf.all.accept_redirects = 0
    net.ipv6.conf.all.accept_redirects = 0
    net.ipv4.conf.all.send_redirects = 0
    kernel.randomize_va_space = 2
    fs.protected_hardlinks = 1
    fs.protected_symlinks = 1
    EOF

    # Apply sysctl changes immediately
    sudo sysctl --system

    # --- Tor Configuration ---
    # Configures Tor to only listen locally for SOCKS connections.
    sudo tee /etc/tor/torrc > /dev/null <<'EOF'
    SocksPort 9050
    SocksListenAddress 127.0.0.1
    EOF
}

setup_zsh() {
    # --- Package Installation ---
    # Installs Zsh, helpful Zsh plugins, and utilities used in the Zsh config.
    install_pkg zsh zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search neovim eza coreutils gawk sed procps-ng fzf bat ripgrep tmux fastfetch alacritty wl-clipboard xclip lazygit ranger

    # --- Link Dotfiles ---
    # Symlink the main Zsh configuration to the user's home directory.
    link "$SCRIPT_DIR/config/zsh/.zshrc" "$ORIGINAL_HOME/.zshrc"

    # Symlink the scripts folder to the user's home.
    # Provides easy access to custom scripts via ~/.scripts.
    link "$SCRIPT_DIR/config/zsh/.scripts" "$ORIGINAL_HOME/.scripts"

    link "$SCRIPT_DIR/config/nvim" "$ORIGINAL_HOME/.config/nvim"
    link "$SCRIPT_DIR/config/alacritty" "$ORIGINAL_HOME/.config/alacritty"
    link "$SCRIPT_DIR/config/fastfetch" "$ORIGINAL_HOME/.config/fastfetch"
}

install_i3() {
    # --- Package Installation ---
    # Installs i3, a tiling window manager.
    install_pkg i3 kvantum

    # --- Link Dotfiles ---
    # Symlink the main i3 configuration to the user's home directory.
}

install_theme() {
    # --- Package Installation ---
    install_pkg kvantum

    # Symlink Kvantum and GTK themes to the user's home.
    link "$SCRIPT_DIR/config/theme/Kvantum" "$ORIGINAL_HOME/.config/Kvantum"
    link "$SCRIPT_DIR/config/theme/gtk-3.0" "$ORIGINAL_HOME/.config/gtk-3.0"
    link "$SCRIPT_DIR/config/theme/gtk-4.0" "$ORIGINAL_HOME/.config/gtk-4.0"
    link "$SCRIPT_DIR/config/theme/.themes" "$ORIGINAL_HOME/.themes"
}

# =====================================
# 🚦 Execute Selected Tasks
# =====================================

if normalize "$install_security"; then setup_security; fi
if normalize "$install_zsh"; then setup_zsh; fi
if normalize "$install_i3"; then install_i3; fi
if normalize "$install_theme"; then install_theme; fi
