-- =============================================================================
-- after/plugin/treesitter.lua - treesitter configuration
--
-- Treesitter provides fast, accurate syntax highlighting and powers several
-- other plugins (autotag, indent-blankline scope, autopairs context).
--
-- nvim-treesitter v1.0+ removed the `nvim-treesitter.configs` module.
-- Setup is now done via require("nvim-treesitter") directly, and syntax
-- highlighting is handled by neovim's built-in vim.treesitter layer.
--
-- auto_install = true means any missing grammar is downloaded automatically
-- when you open a file of that type.
-- =============================================================================

require("nvim-treesitter").setup(
{
    -- Grammars to always keep installed
    ensure_installed =
    {
        "javascript",
        "typescript",
        "tsx",
        "html",
        "css",
        "htmldjango",
        "python",
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "vue",
    },
    sync_install = false, -- install grammars asynchronously
    auto_install = true,  -- install missing grammars on first open
})

-- Improve Django/Jinja template highlighting by linking HTML tag highlight
-- groups to more meaningful token types.
vim.cmd([[
    highlight link htmlTagName     Identifier
    highlight link htmlTagDelimiter Statement
    highlight link htmlSpecialChar Keyword
]])
