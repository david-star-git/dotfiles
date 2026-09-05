-- =============================================================================
-- lua/star/plugins/treesitter.lua - syntax highlighting
--
-- Powers highlighting plus several other plugins (autotag, indent-blankline
-- scope, autopairs context).
-- =============================================================================

return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter").setup({
            ensure_installed = {
                "javascript",
                "typescript",
                "tsx",
                "html",
                "css",
                "htmldjango",
                "python",
                "c",
                "cpp",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "markdown",
                "markdown_inline",
                "vue",
                "json",
                "yaml",
                "bash",
            },
            sync_install = false,
            auto_install = true,
        })

        -- Improve Django/Jinja template highlighting.
        vim.cmd([[
            highlight link htmlTagName     Identifier
            highlight link htmlTagDelimiter Statement
            highlight link htmlSpecialChar Keyword
        ]])
    end,
}
