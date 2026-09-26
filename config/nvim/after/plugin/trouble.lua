-- =============================================================================
-- after/plugin/trouble.lua - diagnostics / references / quickfix list
--
--   <leader>xx  diagnostics for the whole workspace
--   <leader>xX  diagnostics for the current buffer only
--   <leader>cs  symbols outline (document symbols)
--   <leader>cl  LSP references/definitions/implementations for the symbol
--               under the cursor, in a window on the right
--   <leader>xL  location list
--   <leader>xQ  quickfix list
-- =============================================================================

require("trouble").setup()

local map = function(lhs, cmd, desc)
    vim.keymap.set("n", lhs, function()
        vim.cmd(cmd)
    end, { silent = true, desc = desc })
end

map("<leader>xx", "Trouble diagnostics toggle", "Diagnostics (Trouble)")
map("<leader>xX", "Trouble diagnostics toggle filter.buf=0", "Buffer diagnostics (Trouble)")
map("<leader>cs", "Trouble symbols toggle focus=false", "Symbols (Trouble)")
map("<leader>cl", "Trouble lsp toggle focus=false win.position=right", "LSP references (Trouble)")
map("<leader>xL", "Trouble loclist toggle", "Location list (Trouble)")
map("<leader>xQ", "Trouble qflist toggle", "Quickfix list (Trouble)")

