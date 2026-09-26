-- =============================================================================
-- after/plugin/dadbod.lua - database client + drawer UI + completion
--
-- Connections aren't defined here since they're project/secret-specific.
-- Point vim.g.dbs at your own connection strings (in a file that's NOT
-- committed to git), or set the DBUI_URL environment variable, e.g.:
--   vim.g.dbs = { dev = "postgres://user:pass@localhost:5432/mydb" }
--
-- <leader>D toggles the DBUI drawer. Once inside, or in any .sql buffer,
-- writing the file (:w) runs the query against the connected database.
-- =============================================================================

vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod_ui"
vim.g.db_ui_tmp_query_location = vim.fn.stdpath("data") .. "/dadbod_ui/tmp"
-- A big query re-running every time you save can be surprising/slow -
-- require an explicit :DB or <leader>S (dadbod-ui's default) instead.
vim.g.db_ui_execute_on_save = false

vim.keymap.set("n", "<leader>D", "<cmd>DBUIToggle<CR>", { silent = true, desc = "Toggle DBUI" })

-- nvim-cmp completion for table/column names in sql buffers - added
-- alongside the existing sources rather than replacing them, so LSP/buffer/
-- path completion still work in the same buffer.
vim.api.nvim_create_autocmd("FileType",
{
    pattern = { "sql", "mysql", "plsql" },
    callback = function()
        local cmp = require("cmp")
        local sources = vim.tbl_map(function(source)
            return { name = source.name }
        end, cmp.get_config().sources)
        table.insert(sources, { name = "vim-dadbod-completion" })
        cmp.setup.buffer({ sources = sources })
    end,
})

