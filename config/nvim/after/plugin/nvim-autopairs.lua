-- =============================================================================
-- after/plugin/nvim-autopairs.lua - auto bracket/quote pairing
--
-- Automatically inserts the closing pair for (, [, {, ", ', ` as you type.
-- Uses treesitter for smarter context awareness (e.g. doesn't pair inside
-- strings or comments where it would be wrong).
--
-- cmp integration: when you accept a completion that ends with a function call,
-- nvim-autopairs adds the closing parenthesis automatically.
-- =============================================================================

require("nvim-autopairs").setup(
{
    check_ts = true, -- use treesitter for smarter pairing
    enable_check_bracket_line = true, -- don't pair if closing char already exists on line
    map_cr = true, -- auto-expand {} on Enter (works with init.lua smart Enter)
    map_bs = true, -- Backspace deletes both chars of an empty pair
})

-- Wire up nvim-autopairs to nvim-cmp so accepted completions also close pairs.
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

