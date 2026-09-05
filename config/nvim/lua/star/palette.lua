-- =============================================================================
-- lua/star/palette.lua - the "macglass" palette
--
-- A custom macOS-inspired dark palette: neutral graphite backgrounds (the same
-- family macOS itself uses for dark-mode window chrome) plus Apple's system
-- accent colors. System Green is the primary accent everywhere: cursor, git
-- signs, the active statusline mode, selections, borders on the focused
-- window.
--
-- This same palette is mirrored by hand in:
--   ~/.config/kitty/kitty.conf   (terminal colors)
--   ~/.config/tmux/theme.conf    (status bar)
-- so nvim, tmux, and kitty all read as one consistent surface. If you ever
-- want to retheme, this file is the single source of truth on the nvim side.
-- =============================================================================

return {
    -- ── Backgrounds (graphite, macOS dark-mode window chrome) ────────────────
    bg           = "#1a1a1c", -- editor background
    bg_dim       = "#161618", -- inactive windows / non-current NC background
    bg_elevated  = "#232326", -- statusline, floating windows, popups (the "glass" panel)
    bg_highlight = "#28282b", -- cursorline, pmenu selection background
    bg_selection = "#233b2c", -- visual-mode selection (green-tinted graphite)
    bg_search    = "#2c3a2f", -- search match background (green-tinted)

    -- ── Borders / separators ──────────────────────────────────────────────────
    border        = "#3a3a3d", -- inactive float / split border
    border_accent = "#30d158", -- focused float border (system green)

    -- ── Foreground ────────────────────────────────────────────────────────────
    fg           = "#e5e5e7", -- labelColor
    fg_dim       = "#a1a1a6", -- secondaryLabel
    fg_muted     = "#6e6e73", -- tertiaryLabel (comments)
    fg_disabled  = "#48484a", -- quaternaryLabel

    -- ── Apple system accent colors (dark-mode values) ────────────────────────
    green   = "#30d158", -- systemGreen — the accent
    green_bright = "#32d74b",
    mint    = "#66d4a0", -- softened green, used for strings
    blue    = "#0a84ff", -- systemBlue
    cyan    = "#64d2ff", -- systemCyan
    teal    = "#40c8e0", -- systemTeal
    purple  = "#bf5af2", -- systemPurple
    pink    = "#ff7ab2", -- systemPink (softened)
    red     = "#ff453a", -- systemRed
    orange  = "#ff9f0a", -- systemOrange
    yellow  = "#ffd60a", -- systemYellow
    indigo  = "#5e5ce6", -- systemIndigo
    gray    = "#8e8e93", -- systemGray
}
