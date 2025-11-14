local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader> ', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>g', builtin.git_files, { desc = 'Telescope find files Git' })
vim.keymap.set('n', '<leader>f', function()
builtin.grep_string({ search = vim.fn.input("Grep > ") });

require("telescope").load_extension("noice")
end)
