for pkg in i3 kvantum dolphin picom polybar rofi librewolf-bin dex xss-lock i3lock xorg-xrandr feh mpd dunst mate-polkit psmisc xorg-xset dmenu zsh zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search neovim eza coreutils gawk sed procps-ng fzf bat ripgrep tmux fastfetch alacritty wl-clipboard xclip lazygit ranger linux-hardened apparmor ufw dnscrypt-proxy tor torsocks bleachbit aide clamav rkhunter lynis firejail bubblewrap; do
    if pacman -Si "$pkg" &>/dev/null; then
        echo "✅ $pkg → in official repos (pacman)"
    elif yay -Si "$pkg" &>/dev/null; then
        echo "🌀 $pkg → in AUR (yay)"
    else
        echo "❌ $pkg → NOT found!"
    fi
done

