-- =============================================================================
-- after/plugin/devdocs.lua - offline devdocs.io documentation
--
-- Docs aren't bundled - you need to fetch the registry once and install a
-- doc set per language before this does anything:
--   :DevdocsFetch                      refresh the list of available docs
--   :DevdocsInstall <name>             e.g. python~3.12, javascript, lua-5.4
--
-- <leader>K opens the docs for the current buffer's filetype (mirrors vim's
-- own K-for-"look this up" convention, just under <leader> since bare K is
-- already LSP hover). Uses ayoisaiah's fork since the original
-- luckasRanarison/nvim-devdocs is archived/unmaintained.
-- =============================================================================
-- require("nvim-devdocs").setup(
-- {
--     ensure_installed =
--     {
--         "c",
--         "cpp",
--         "python~3.14",
--         "lua~5.1",
--         "javascript",
--         "typescript",
--         "node",
--         "npm",
--         "cmake",
--         "markdown",
--         "openjdk~21",
--         "git",
--         "docker",
--     },
-- })
--

vim.keymap.set(
    "n",
    "<leader>K",
    "<cmd>DevdocsOpenCurrent<CR>",
    { silent = true, desc = "Open DevDocs for current filetype" }
)

