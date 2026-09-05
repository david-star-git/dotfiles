-- =============================================================================
-- lua/star/plugins/indent-blankline.lua - indent guides
--
-- Switched from rainbow indent guides to a single subtle guide color plus a
-- green highlight on the current scope — quieter and more in line with a
-- clean macOS aesthetic than a full rainbow. (Colors come from the IndentGuide
-- / IndentGuideActive groups in colors/macglass.lua — change those if you
-- want the rainbow back.)
-- =============================================================================

return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        indent = { highlight = "IndentGuide", char = "│" },
        scope = { highlight = "IndentGuideActive", show_start = false, show_end = false },
    },
}
