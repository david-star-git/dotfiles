-- =============================================================================
-- lua/star/remap.lua - keybindings
--
-- Movement is shifted one key to the right to match the German keyboard layout
-- and stay consistent with tmux and i3:
--   j = left   k = up   l = down   ö = right
--
-- All three modes (normal, visual, operator-pending) get the same remaps so
-- motions, selections, and text objects all behave consistently.
-- =============================================================================

vim.g.mapleader = " " -- Space as leader key

-- ── Movement ──────────────────────────────────────────────────────────────────
-- Remap hjkl → jklö so navigation matches tmux and i3.
vim.keymap.set("n", "j", "h") -- j = left
vim.keymap.set("n", "k", "k") -- k = up    (unchanged, just explicit)
vim.keymap.set("n", "l", "j") -- l = down
vim.keymap.set("n", "ö", "l") -- ö = right

vim.keymap.set("v", "j", "h")
vim.keymap.set("v", "k", "k")
vim.keymap.set("v", "l", "j")
vim.keymap.set("v", "ö", "l")

vim.keymap.set("o", "j", "h")
vim.keymap.set("o", "k", "k")
vim.keymap.set("o", "l", "j")
vim.keymap.set("o", "ö", "l")

-- ── Line navigation ───────────────────────────────────────────────────────────
-- gg → beginning of line (^ — first non-blank character)
-- hh → end of line ($)
vim.keymap.set("n", "gg", "^")
vim.keymap.set("n", "hh", "$")
vim.keymap.set("v", "gg", "^")
vim.keymap.set("v", "hh", "$")
vim.keymap.set("o", "gg", "^")
vim.keymap.set("o", "hh", "$")

-- ── Delete without yanking ────────────────────────────────────────────────────
-- Sends deleted lines to the black hole register instead of overwriting the
-- clipboard — paste still works as expected after a dd.
vim.keymap.set("n", "dd", '"_dd')

-- ── Pane navigation (vim-tmux-navigator) ─────────────────────────────────────
-- Alt+j/k/l/ö moves between nvim splits directly, for when you're using nvim
-- without tmux around it. (Inside tmux, the *same* keys instead go through
-- tmux.conf's own Alt+jklö bindings + vim-tmux-navigator's "is_vim" detection,
-- which is what makes Alt+jklö cross seamlessly between tmux panes and nvim
-- splits — see plugins/tmux-navigator.lua for the full explanation.)
--
-- Fixed: these were previously written as "M-j" etc. (a plain 3-character
-- string, matching the literal keys M, -, j) instead of "<M-j>" (Alt+j) —
-- a typo that meant this block did nothing. They now work as intended.
vim.keymap.set("n", "<M-j>", ":wincmd h<CR>", { silent = true })
vim.keymap.set("n", "<M-k>", ":wincmd k<CR>", { silent = true })
vim.keymap.set("n", "<M-l>", ":wincmd j<CR>", { silent = true })
vim.keymap.set("n", "<M-ö>", ":wincmd l<CR>", { silent = true })
