vim.g.mapleader = " "

-- movement shifted one key to the right
vim.keymap.set("n", "j", "h")  -- j = left
vim.keymap.set("n", "l", "j")  -- k = up
vim.keymap.set("n", "k", "k")  -- l = down
vim.keymap.set("n", "ö", "l")  -- ö = right

vim.keymap.set("v", "j", "h")
vim.keymap.set("v", "l", "j")
vim.keymap.set("v", "k", "k")
vim.keymap.set("v", "ö", "l")

vim.keymap.set("o", "j", "h")
vim.keymap.set("o", "l", "j")
vim.keymap.set("o", "k", "k")
vim.keymap.set("o", "ö", "l")

-- end and beginning of line
vim.keymap.set("n", "gg", "^") -- g = go to beginning of line
vim.keymap.set("n", "hh", "$") -- h = go to end of line

vim.keymap.set("v", "gg", "^")
vim.keymap.set("v", "hh", "$")

vim.keymap.set("o", "gg", "^")
vim.keymap.set("o", "hh", "$")

-- prevents deleted text from replacing clipboard
vim.keymap.set("n", "dd", '"_dd')

-- vim/tmux
vim.keymap.set('n', 'M-j', ':wincmd h<CR>')
vim.keymap.set('n', 'M-k', ':wincmd k<CR>')
vim.keymap.set('n', 'M-l', ':wincmd j<CR>')
vim.keymap.set('n', 'M-ö', ':wincmd l<CR>')
