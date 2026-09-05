-- =============================================================================
-- lua/star/plugins/gitsigns.lua - git change indicators in the sign column
--
-- New addition. Your lualine config already had a "diff" component in its
-- status line, but nothing was ever providing that data — lualine's diff
-- component reads from gitsigns (or vim-signify), and neither was installed,
-- so it silently showed nothing. This both fixes that and adds the usual
-- signcolumn +/~/- markers, colored via the accent palette (added = green).
-- =============================================================================

return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "│" },
            change = { text = "│" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
        },
    },
}
