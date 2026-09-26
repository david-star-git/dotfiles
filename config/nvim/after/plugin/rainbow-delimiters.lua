-- =============================================================================
-- after/plugin/rainbow-delimiters.lua - rainbow-colored nested brackets
--
-- Config is a global vim table (not a setup() call) - each nesting depth of
-- brackets/parens gets the next color in the `highlight` list, cycling back
-- to the start once it runs out.
-- =============================================================================

local rainbow_delimiters = require("rainbow-delimiters")


vim.g.rainbow_delimiters =
{
    strategy =
    {
        [""] = rainbow_delimiters.strategy["global"],
        vim = rainbow_delimiters.strategy["local"], -- vimscript nests too deeply for a global strategy
    },
    query =
    {
        [""] = "rainbow-delimiters",
        lua = "rainbow-blocks", -- also colors do/end, if/end, function/end blocks
    },
    highlight =
    {
        "RainbowDelimiterRed",
        "RainbowDelimiterYellow",
        "RainbowDelimiterBlue",
        "RainbowDelimiterOrange",
        "RainbowDelimiterGreen",
        "RainbowDelimiterViolet",
        "RainbowDelimiterCyan",
    },
}

