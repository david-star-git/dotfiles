-- =============================================================================
-- after/plugin/tabout.lua - tab past closing brackets/quotes
--
-- With the cursor inside (), [], {}, '', "", or ``, <Tab> jumps past the
-- closing character instead of inserting a literal tab. <S-Tab> does the
-- same backwards. Falls through to nvim-cmp's own <Tab> (selecting a
-- completion) whenever the completion popup menu is open - packer's
-- `after = "nvim-cmp"` on the plugin declaration guarantees load order.
-- =============================================================================

require("tabout").setup(
{
    tabkey = "<Tab>",
    backwards_tabkey = "<S-Tab>",
    act_as_tab = true, -- indent normally when there's nothing to tab out of
    act_as_shift_tab = false,
    completion = true, -- let <Tab> still work inside the cmp popup menu
    tabouts =
    {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = "`", close = "`" },
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
    },
    ignore_beginning = true,
})

