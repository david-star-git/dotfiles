for pkg in zsh zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search neovim eza coreutils gawk sed procps-ng fzf bat ripgrep; do
    if pacman -Si "$pkg" &>/dev/null; then
        echo "✅ $pkg → in official repos (pacman)"
    elif yay -Si "$pkg" &>/dev/null; then
        echo "🌀 $pkg → in AUR (yay)"
    else
        echo "❌ $pkg → NOT found!"
    fi
done

