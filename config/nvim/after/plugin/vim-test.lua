-- =============================================================================
-- after/plugin/vim-test.lua - test runner keybinds
--
-- vim-test runs tests from inside nvim and sends output to a tmux pane via
-- vimux. The pane opens automatically and stays open after the run.
--
-- <leader>t - run the test nearest to the cursor
-- <leader>T - run all tests in the current file
-- <leader>a - run the entire test suite
-- <leader>l - re-run the last test that was run
-- <leader>g - open the file where the last test was defined
-- =============================================================================

vim.keymap.set("n", "<leader>t", ":TestNearest<CR>", { silent = true })
vim.keymap.set("n", "<leader>T", ":TestFile<CR>", { silent = true })
vim.keymap.set("n", "<leader>a", ":TestSuite<CR>", { silent = true })
vim.keymap.set("n", "<leader>l", ":TestLast<CR>", { silent = true })
vim.keymap.set("n", "<leader>g", ":TestVisit<CR>", { silent = true })

-- Use vimux to send test output to a tmux pane instead of a new nvim buffer.
-- This keeps the editor clean and lets you scroll test output freely.
vim.cmd("let test#strategy = 'vimux'")
