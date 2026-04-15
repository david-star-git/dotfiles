-- =============================================================================
-- after/plugin/treesitter.lua - treesitter configuration
--
-- Treesitter provides fast, accurate syntax highlighting and powers several
-- other plugins (autotag, indent-blankline scope, autopairs context).
--
-- auto_install = true means any missing grammar is downloaded automatically
-- when you open a file of that type.
-- =============================================================================

require("nvim-treesitter.configs").setup(
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
    auto_install = true, -- install missing grammars on first open
    highlight =
    {
        enable = true,
        -- Don't mix treesitter highlighting with the old regex-based syntax —
        -- they conflict and produce ugly results.
        additional_vim_regex_highlighting = false,
    },
})

-- nvim-ts-autotag — auto-close/rename HTML tags using the treesitter tree.
-- filetypes covers HTML, Django templates, and React/Vue JSX.
require("nvim-ts-autotag").setup(
{
    enable = true,
    filetypes = { "html", "xml", "javascriptreact", "typescriptreact", "htmldjango" },
})

-- Improve Django/Jinja template highlighting by linking HTML tag highlight
-- groups to more meaningful token types.
vim.cmd([[
    highlight link htmlTagName     Identifier
    highlight link htmlTagDelimiter Statement
    highlight link htmlSpecialChar Keyword
]])

