-- =============================================================================
-- after/plugin/autotag.lua - nvim-ts-autotag
--
-- Auto-closes and auto-renames HTML/JSX/Vue tags using treesitter.
-- Much more reliable than regex-based tag completion because it understands
-- the actual syntax tree.
-- =============================================================================

require("nvim-ts-autotag").setup(
{
    opts =
    {
        enable_close = true,     -- auto-close opening tags: <div| → <div></div>
        enable_rename = true,    -- renaming <div> also renames </div>
        enable_close_on_slash = false, -- don't auto-close on </  (let treesitter handle it)
    },
})

