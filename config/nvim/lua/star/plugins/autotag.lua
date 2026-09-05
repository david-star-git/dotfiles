-- =============================================================================
-- lua/star/plugins/autotag.lua - HTML/JSX/Vue tag auto-close & auto-rename
--
-- Uses treesitter to understand the actual syntax tree rather than regex, so
-- it's reliable across HTML, JSX, TSX, and Vue.
-- =============================================================================

return {
    "windwp/nvim-ts-autotag",
    ft = { "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "xml", "htmldjango" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
    },
}
