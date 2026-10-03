-- =============================================================================
-- after/plugin/smartcolumn.lua - line length guide
--
-- Shows a vertical colorcolumn only when a line exceeds the limit, so the
-- column stays hidden in files that respect it. Limit is 100 characters by
-- default and 120 for java.
--
-- scope = "file" shows the column while any line in the buffer is too long.
-- Switch to "line" to show it only while the cursor line is too long.
-- =============================================================================

require("smartcolumn").setup(
{
    colorcolumn = "100",
    -- "file": column appears if any line in the file is too long
    -- "line": column appears only while the cursor line is too long
    scope = "file",
    custom_colorcolumn =
    {
        java = "120",
    },
    disabled_filetypes = { "help", "text", "markdown", "alpha", "NvimTree", "lazy", "mason" },
})

