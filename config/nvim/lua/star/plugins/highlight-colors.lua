-- =============================================================================
-- lua/star/plugins/highlight-colors.lua - nvim-highlight-colors
--
-- Shows a colored swatch next to color values in the source code.
-- Supports hex, short hex, rgb, hsl, ansi, xterm256, CSS variables, and
-- named colors. Tailwind is disabled (enable if working with Tailwind CSS).
--
-- Render mode is "virtual" — a small swatch appears inline next to the color
-- value without modifying the actual background of the text.
--
-- (Dropped the two hardcoded --theme-primary-color / --theme-secondary-color
-- entries that were here before — those were specific to one old project and
-- not something a general dotfiles config should carry around. Add your own
-- back under custom_colors if you need them for a specific project.)
-- =============================================================================

return {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        render = "virtual",
        virtual_symbol = "■",
        virtual_symbol_prefix = "",
        virtual_symbol_suffix = " ",
        virtual_symbol_position = "inline",
        enable_hex = true,
        enable_short_hex = true,
        enable_rgb = true,
        enable_hsl = true,
        enable_ansi = true,
        enable_xterm256 = true,
        enable_xtermTrueColor = true,
        enable_hsl_without_function = true,
        enable_var_usage = true,
        enable_named_colors = true,
        enable_tailwind = false,
        custom_colors = {},
        exclude_filetypes = {},
        exclude_buftypes = {},
    },
}
