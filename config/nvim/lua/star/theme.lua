-- =============================================================================
-- lua/star/theme.lua - apply the macglass colorscheme + "glass" window options
--
-- Loaded eagerly (before plugins) from lua/star/init.lua so the UI never
-- flashes an unstyled default theme on startup.
--
-- The transparency here is deliberate: Normal/NormalNC have no background
-- (see colors/macglass.lua), which lets kitty's background_opacity and
-- background_blur show through the editor. Floating windows get a real
-- background color PLUS winblend/pumblend, so they read as frosted-glass
-- panels sitting above that blur rather than fully see-through.
-- =============================================================================

vim.cmd.colorscheme("macglass")

-- Floating window translucency ("glass" panels: hover docs, Telescope,
-- nvim-tree, noice, which-key, completion menu).
vim.o.winblend = 12
vim.o.pumblend = 12

-- Cleaner separators/whitespace glyphs — thin lines instead of vim's default
-- heavy pipe, no trailing "~" filler rows below the buffer.
vim.opt.fillchars = {
    eob = " ",
    fold = " ",
    horiz = "─",
    horizup = "┴",
    horizdown = "┬",
    vert = "│",
    vertleft = "┤",
    vertright = "├",
    verthoriz = "┼",
}
