--- =============================================================================
-- after/plugin/highlight-colors.lua - nvim-highlight-colors
--
-- Shows a colored swatch next to color values in the source code.
-- Supports hex, short hex, rgb, hsl, ansi, xterm256, CSS variables, and
-- named colors. Tailwind is disabled (enable if working with Tailwind CSS).
--
-- Render mode is "virtual" — a small ■ symbol appears inline next to the color
-- value without modifying the actual background of the text.
-- =============================================================================

vim.opt.termguicolors = true

require("nvim-highlight-colors").setup(
{
    render = "virtual", -- 'background' | 'foreground' | 'virtual'
    virtual_symbol = "■",
    virtual_symbol_prefix = "",
    virtual_symbol_suffix = " ",
    virtual_symbol_position = "inline", -- mimics VS Code style
    -- Color format support
    enable_hex = true, -- #FFFFFF
    enable_short_hex = true, -- #fff
    enable_rgb = true, -- rgb(0 0 0)
    enable_hsl = true, -- hsl(150deg 30% 40%)
    enable_ansi = true, -- \033[0;34m
    enable_xterm256 = true, -- \033[38;5;118m
    enable_xtermTrueColor = true, -- \033[38;2;118;64;90m
    enable_hsl_without_function = true, -- --foreground: 0 69% 69%
    enable_var_usage = true, -- var(--color)
    enable_named_colors = true, -- green, red, etc.
    enable_tailwind = false, -- bg-blue-500 (enable if using Tailwind)
    -- Custom color mappings for CSS variables used in this project
    custom_colors =
    {
        { label = "%-%-theme%-primary%-color", color = "#0f1219" },
        { label = "%-%-theme%-secondary%-color", color = "#5a5d64" },
    },
    exclude_filetypes = {},
    exclude_buftypes = {},
    exclude_buffer = function(bufnr) end,
})

