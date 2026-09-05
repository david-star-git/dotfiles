-- =============================================================================
-- lua/star/plugins/autopairs.lua - auto bracket/quote pairing
--
-- Automatically inserts the closing pair for (, [, {, ", ', ` as you type.
-- Uses treesitter for smarter context awareness (doesn't pair inside strings
-- or comments where it would be wrong). The cmp integration (closing pairs
-- on accepted completions) is wired in cmp.lua.
-- =============================================================================

return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
        require("nvim-autopairs").setup({
            check_ts = true,
            enable_check_bracket_line = true,
            map_cr = true, -- auto-expand {} on Enter (works with the smart-Enter mapping in init.lua)
            map_bs = true, -- Backspace deletes both chars of an empty pair
        })
    end,
}
