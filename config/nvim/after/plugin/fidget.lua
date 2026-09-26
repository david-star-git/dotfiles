-- =============================================================================
-- after/plugin/fidget.lua - LSP progress notifications
--
-- Replaces noice.nvim's built-in "mini" progress view (indexing, workspace
-- symbols, etc) - see the lsp.progress.enabled = false note in noice.lua.
-- Running both would show the same progress twice, in two different corners.
-- =============================================================================

require("fidget").setup()

