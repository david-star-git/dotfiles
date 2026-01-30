-- Treesitter setup
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "javascript",
    "html",
    "python",
    "css",
    "c",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "typescript",
    "tsx",
    "vue",
    "htmldjango",
  },

  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,  -- don't mix with old regex syntax
  },
}

-- Autotag setup (new plugin)
require('nvim-ts-autotag').setup({
  enable = true,
  filetypes = { "html", "xml", "javascriptreact", "typescriptreact", "htmldjango" },
})

-- Optional: Force Jinja syntax highlighting for htmldjango
vim.cmd [[
  highlight link htmlTagName Identifier
  highlight link htmlTagDelimiter Statement
  highlight link htmlSpecialChar Keyword
]]

