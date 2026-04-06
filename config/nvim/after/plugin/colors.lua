-- =============================================================================
-- after/plugin/colors.lua - colorscheme
--
-- Applies Catppuccin Mocha and clears background highlights so the terminal's
-- transparency shows through. Called once on startup.
-- =============================================================================

function ColorMyPencils(color)
    color = color or "catppuccin"
    vim.cmd.colorscheme(color)

    -- Clear Normal and NormalFloat backgrounds so the terminal transparency
    -- is visible behind text and floating windows (e.g. LSP hover docs).
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMyPencils()
