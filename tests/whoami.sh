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
            # Fallback (e.g., script run as root manually)
            export ORIGINAL_USER="root"
            export ORIGINAL_HOME="/root"
        fi
    fi
fi

echo "👤 You are currently logged in as $ORIGINAL_USER"
echo "   Your home directory is $ORIGINAL_HOME"