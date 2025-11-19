#!/bin/bash

# =====================================================
# Privilege Handling 
# =====================================================

# If script is run as root - > stop immediately
if [ "$EUID" -eq 0 ]; then
    echo -e "\n🚫 Do NOT run this script as root!"
    echo "   Run it as a normal user — the script will use sudo when needed."
    exit 1
fi

# Script is running as a normal user - > store original user info
export ORIGINAL_USER="$USER"
export ORIGINAL_HOME="$HOME"

# --- Source Script Directory ---
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# =====================================
# Utility Functions for Setup Tasks
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

# --- Symlink Creation ---
# Creates a symbolic link safely.
# If the destination already exists (file, directory, or symlink),
# it is removed and replaced with a new link.
link() {
    local src=$1
    local dest=$2

    # If source doesn't exist, create a directory if destination looks like a directory
    if [ ! -e "$src" ]; then
        echo "Source $src does not exist. Creating directory..."
        mkdir -p "$src"
    fi

    # Remove existing destination
    if [ -L "$dest" ] || [ -d "$dest" ] || [ -f "$dest" ]; then
        echo "Replacing $dest"
        rm -rf "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    echo "Linked $dest → $src"
}

mkdir -p "$ORIGINAL_HOME/.config"

# =====================================
# System Security & Hardening Setup
# =====================================

setup_security() {
    # --- UFW Firewall Configuration ---
    # Default deny all incoming traffic, allow all outgoing.
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable

    # --- Enable Security Services ---
    # Automatically start and enable key protection services.
    sudo systemctl enable ufw --now

    # --- Disable Unused / Risky Services ---
    # Minimizes the attack surface by stopping unneeded daemons.
    sudo systemctl disable --now avahi-daemon
    sudo systemctl disable --now cups
    sudo systemctl disable --now bluetooth
    sudo systemctl disable --now sshd

    # --- Sysctl Hardening ---
    # Kernel and network-level hardening parameters.
    sudo tee /etc/sysctl.d/99-sysctl.conf >/dev/null <<'EOF'
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
    sudo tee /etc/tor/torrc >/dev/null <<'EOF'
SocksPort 9050
SocksListenAddress 127.0.0.1
EOF
}

setup_zsh() {
    mkdir -p "$ORIGINAL_HOME/.config"
    # --- Link Dotfiles ---
    # Symlink the main Zsh configuration to the user's home directory.
    link "$SCRIPT_DIR/config/zsh/.zshrc" "$ORIGINAL_HOME/.zshrc"

    # Symlink the scripts folder to the user's home.
    # Provides easy access to custom scripts via ~/.scripts.
    link "$SCRIPT_DIR/config/zsh/.scripts" "$ORIGINAL_HOME/.scripts"

    link "$SCRIPT_DIR/config/nvim" "$ORIGINAL_HOME/.config/nvim"
    mkdir -p "$ORIGINAL_HOME/.config/nvim/site/pack/packer/start"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$ORIGINAL_HOME/.config/nvim/site/pack/packer/start/packer.nvim"

    link "$SCRIPT_DIR/config/alacritty" "$ORIGINAL_HOME/.config/alacritty"
    link "$SCRIPT_DIR/config/fastfetch" "$ORIGINAL_HOME/.config/fastfetch"

    link "$SCRIPT_DIR/config/tmux" "$ORIGINAL_HOME/.config/tmux"
    mkdir -p "$ORIGINAL_HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$ORIGINAL_HOME/.tmux/plugins/tpm"
}

install_i3() {
    mkdir -p "$ORIGINAL_HOME/.config"
    # --- Link Dotfiles ---
    # Symlink the main i3 configuration to the user's home directory.
    link "$SCRIPT_DIR/config/.xinitrc" "$ORIGINAL_HOME/.xinitrc"
    link "$SCRIPT_DIR/config/i3" "$ORIGINAL_HOME/.config/i3"
    link "$SCRIPT_DIR/config/polybar" "$ORIGINAL_HOME/.config/polybar"
    link "$SCRIPT_DIR/config/picom" "$ORIGINAL_HOME/.config/picom"
    link "$SCRIPT_DIR/config/rofi" "$ORIGINAL_HOME/.config/rofi"

    mkdir -p "$ORIGINAL_HOME/.local/bin"
    find "$SCRIPT_DIR/usr/local/bin" -type f -exec chmod +x {} \;
    cp -ran "$SCRIPT_DIR/usr/local/bin/"* "$ORIGINAL_HOME/.local/bin"
}

install_theme() {
    mkdir -p "$ORIGINAL_HOME/.config"
    # Symlink Kvantum and GTK themes to the user's home.
    link "$SCRIPT_DIR/config/theme/Kvantum" "$ORIGINAL_HOME/.config/Kvantum"
    link "$SCRIPT_DIR/config/theme/gtk-3.0" "$ORIGINAL_HOME/.config/gtk-3.0"
    link "$SCRIPT_DIR/config/theme/gtk-4.0" "$ORIGINAL_HOME/.config/gtk-4.0"
    link "$SCRIPT_DIR/config/theme/.themes" "$ORIGINAL_HOME/.themes"
    link "$SCRIPT_DIR/fonts" "$ORIGINAL_HOME/.fonts"
}

# =====================================
# Execute Tasks
# =====================================
sudo pacman -S --noconfirm i3-wm kvantum dolphin picom polybar rofi dex xss-lock i3lock xorg-xrandr feh mpd dunst mate-polkit psmisc xorg-xset dmenu zsh zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search neovim eza coreutils gawk sed procps-ng fzf bat ripgrep tmux fastfetch alacritty wl-clipboard xclip lazygit ranger linux-hardened ufw tor torsocks

ensure_yay
yay -S --noconfirm librewolf-bin aide

setup_security
setup_zsh
install_i3
install_theme
