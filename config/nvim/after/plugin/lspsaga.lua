-- =============================================================================
-- after/plugin/lspsaga.lua - floating-window UI for the LSP client
--
-- lspsaga doesn't attach anything on its own - it just gives nicer UI for
-- the same requests nvim-lspconfig already makes. The keymaps that use it
-- are set on LSP attach in after/plugin/mason.lua's on_attach, right next
-- to the ones they replace/extend. This file only holds lspsaga's own
-- setup() and the handful of keys that don't depend on an attached client
-- (diagnostic jumps, the outline).
--
--   gh          Lspsaga finder (definitions + references, in one list)
--   gd          Lspsaga peek_definition (preview without leaving the buffer)
--   K           Lspsaga hover_doc                        (mason.lua on_attach)
--   <leader>d   Lspsaga goto_definition (jump directly)   (mason.lua on_attach)
--   <leader>rn  Lspsaga rename                             (mason.lua on_attach)
--   <leader>ca  Lspsaga code_action                        (mason.lua on_attach)
--   gl          Lspsaga show_line_diagnostics
--   [e / ]e     previous/next diagnostic
--   <leader>o   toggle the symbol outline
-- =============================================================================

require("lspsaga").setup(
{
    lightbulb = { enable = false },
    -- VS Code-style breadcrumb showing the current symbol hierarchy.
    symbol_in_winbar =
    {
        enable = true,
        separator = " > ",
        hide_keyword = false, -- hide "class", "function", etc.; show only names
        show_file = false,
        folder_level = 0,
    },
})

vim.api.nvim_set_hl(0, "SagaNormal",
{
    bg = "#1e1e2e",
})

vim.api.nvim_set_hl(0, "SagaBorder",
{
    fg = "#585b70",
    bg = "#1e1e2e",
})

vim.api.nvim_set_hl(0, "NormalFloat",
{
    bg = "#1e1e2e",
})

vim.api.nvim_set_hl(0, "FloatBorder",
{
    fg = "#585b70",
    bg = "#1e1e2e",
})

vim.opt.updatetime = 1000

vim.api.nvim_create_autocmd("CursorHold",
{
    callback = function()
        if next(vim.lsp.get_clients({ bufnr = 0 })) then
            vim.lsp.buf.hover({ focus = false })
        end
    end,
})

local map = function(lhs, cmd, desc)
    vim.keymap.set("n", lhs, "<cmd>Lspsaga " .. cmd .. "<CR>", { silent = true, desc = desc })
end

map("gh", "finder", "LSP finder (Lspsaga)")
map("gd", "peek_definition", "Peek definition (Lspsaga)")
map("gl", "show_line_diagnostics", "Line diagnostics (Lspsaga)")
map("[e", "diagnostic_jump_prev", "Previous diagnostic (Lspsaga)")
map("]e", "diagnostic_jump_next", "Next diagnostic (Lspsaga)")
map("<leader>o", "outline", "Toggle outline (Lspsaga)")

