-- =============================================================================
-- lua/star/plugins/vim-test.lua - test runner keybinds
--
-- vim-test runs tests from inside nvim and sends output to a tmux pane via
-- vimux. The pane opens automatically and stays open after the run.
--
-- <leader>t  - run the test nearest to the cursor
-- <leader>T  - run all tests in the current file
-- <leader>a  - run the entire test suite
-- <leader>l  - re-run the last test that was run
-- <leader>tv - open the file where the last test was defined
--
-- Note: this used to be bound to <leader>g, which collided with Telescope's
-- git_files (both packer's alphabetical after/plugin load order and now
-- lazy's loading meant whichever loaded last silently won — telescope's
-- <leader>g never actually fired). Moved to <leader>tv, grouped with the
-- other test-runner keys, and <leader>g is free for git_files.
-- =============================================================================

return {
    "vim-test/vim-test",
    dependencies = { "preservim/vimux" },
    keys = {
        { "<leader>t", "<cmd>TestNearest<CR>", desc = "Test: nearest" },
        { "<leader>T", "<cmd>TestFile<CR>", desc = "Test: file" },
        { "<leader>a", "<cmd>TestSuite<CR>", desc = "Test: suite" },
        { "<leader>l", "<cmd>TestLast<CR>", desc = "Test: last" },
        { "<leader>tv", "<cmd>TestVisit<CR>", desc = "Test: visit last file" },
    },
    config = function()
        -- Send test output to a tmux pane instead of a new nvim buffer — keeps
        -- the editor clean and lets you scroll test output freely.
        vim.g["test#strategy"] = "vimux"
    end,
}
