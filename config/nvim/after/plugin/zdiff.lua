-- =============================================================================
-- after/plugin/zdiff.lua - multi-file diff viewer (Zed-style)
--
--   <leader>zd  uncommitted changes (diff vs HEAD)
--   <leader>zD  changes vs the main branch
--
-- Inside the zdiff buffer itself: <CR> jump to file/line, <Tab> expand or
-- collapse a file, m toggle uncommitted/branch mode, R refresh, q close,
-- gy yank a file:line reference, ? show all keymaps.
-- =============================================================================

require("zdiff").setup()

vim.keymap.set("n", "<leader>zd", function()
    require("zdiff").open()
end, { desc = "Zdiff (uncommitted)" })
vim.keymap.set("n", "<leader>zD", function()
    require("zdiff").open("main")
end, { desc = "Zdiff (vs main)" })

