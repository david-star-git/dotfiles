-- =============================================================================
-- after/plugin/auto-session.lua - per-directory session restore
--
-- Saves the session for each working directory on exit and restores it when
-- nvim starts in that directory: same buffers, cursor line and column, splits,
-- folds, and the nvim-tree window.
--
-- Home, Downloads, and / are suppressed so a stray `nvim` there does not
-- create or restore a session. nvim-tree is closed before saving and reopened
-- after restoring, because its buffer does not restore cleanly on its own.
--
-- Sessions live in ~/.local/share/nvim/sessions/.
-- :SessionDelete clears the current directory's session if it gets corrupted.
-- =============================================================================
-- Needed so sessions store cursor position, folds, and window layout

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

require("auto-session").setup(
{
    auto_save = true,
    auto_restore = true,
    auto_create = true,
    suppressed_dirs = { "~/", "~/Downloads", "/" },
    bypass_save_filetypes = { "alpha" },
    -- nvim-tree buffers do not restore cleanly, so close before saving
    -- and reopen after restoring, then jump back to the editor window.
    pre_save_cmds = { "NvimTreeClose" },
    post_restore_cmds = { "NvimTreeOpen", "wincmd p" },
})

