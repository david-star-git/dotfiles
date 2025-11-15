for pkg in i3 dolphin picom polybar rofi librewolf dex xss-lock i3lock xorg-xrandr feh mpd dunst mate-polkit psmisc xorg-xset dmenu; do
    if pacman -Si "$pkg" &>/dev/null; then
        echo "✅ $pkg → in official repos (pacman)"
    elif yay -Si "$pkg" &>/dev/null; then
        echo "🌀 $pkg → in AUR (yay)"
    else
        echo "❌ $pkg → NOT found!"
    fi
done

