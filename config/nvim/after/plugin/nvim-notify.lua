-- =============================================================================
-- after/plugin/nvim-notify.lua - notification backend
--
-- nvim-notify provides the toast notification system used by noice.nvim and
-- vim.notify(). The background colour is pinned to Catppuccin Mocha's base
-- (#1e1e2e) so notifications don't inherit an unset/transparent background
-- which causes rendering artefacts in some terminals.
-- =============================================================================

require("notify").setup({
    background_colour = "#1e1e2e", -- Catppuccin Mocha base
})

-- Link the NotifyBackground highlight to Normal so the background is consistent
-- with the rest of the editor rather than a hardcoded color.
vim.cmd("highlight link NotifyBackground Normal")
