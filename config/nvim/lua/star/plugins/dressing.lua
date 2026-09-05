-- =============================================================================
-- lua/star/plugins/dressing.lua - nicer vim.ui.select / vim.ui.input
--
-- New addition. noice.nvim covers the cmdline and popup menu, but code
-- action menus, LSP rename prompts, and similar vim.ui.select/input calls
-- aren't part of that — dressing.nvim gives those the same rounded glass-panel
-- treatment so the whole editor feels consistent.
-- =============================================================================

return {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
        input = { border = "rounded", relative = "editor" },
        select = { backend = { "telescope", "builtin" } },
    },
}
