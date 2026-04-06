-- =============================================================================
-- after/plugin/indent-blankline.lua - indent-blankline (ibl)
--
-- Shows vertical indent guide lines with rainbow colors that cycle through
-- nesting levels. Colors are re-registered on every colorscheme change via
-- the HIGHLIGHT_SETUP hook so they always match the current theme's palette.
--
-- Scope highlighting uses treesitter to highlight the current code block's
-- indent guide in a distinct color.
-- =============================================================================

-- Initial setup (minimal — options set below)
require("ibl").setup()

-- Rainbow color cycle — one highlight group per indent level.
-- Colors are from One Dark / a neutral palette that reads well on dark themes.
local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}

local hooks = require("ibl.hooks")

-- Re-register highlight groups whenever the colorscheme changes.
-- Without this hook the colors would be lost on :colorscheme changes.
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

-- Enable rainbow colors for both indent guides and scope highlighting.
vim.g.rainbow_delimiters = { highlight = highlight }
require("ibl").setup({ scope = { highlight = highlight } })

-- Use treesitter extmarks to determine which scope to highlight.
hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
