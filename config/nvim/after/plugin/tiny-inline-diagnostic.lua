-- =============================================================================
-- after/plugin/tiny-inline-diagnostic.lua - inline diagnostic messages
--
-- Renders the diagnostic message inline at the end of the line instead of
-- vim's default virtual text, so this MUST turn the default off (its own
-- docs call this out explicitly) or you'd see the message twice.
-- =============================================================================

require("tiny-inline-diagnostic").setup(
{
    preset = "modern",
    options =
    {
        multilines = { enabled = true }, -- keep multi-line diagnostics readable
        show_source = { enabled = false }, -- server name is usually just noise here
    },
})

vim.diagnostic.config({ virtual_text = false })

