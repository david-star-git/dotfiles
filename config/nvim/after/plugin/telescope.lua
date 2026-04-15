-- =============================================================================
-- after/plugin/telescope.lua - fuzzy finder keybinds
--
-- <leader>Space - find files in the current project
-- <leader>g     - find files tracked by git
-- <leader>f     - grep string across the project (prompts for input)
--
-- The noice extension is loaded so :Noice history is searchable via telescope.
-- =============================================================================

local builtin = require("telescope.builtin")

-- Find any file in the current working directory
vim.keymap.set("n", "<leader> ", builtin.find_files, { desc = "Telescope find files" })

-- Find files tracked by git (respects .gitignore)
vim.keymap.set("n", "<leader>g", builtin.git_files, { desc = "Telescope git files" })

-- Live grep — prompts for a search string then shows all matches
vim.keymap.set("n", "<leader>f", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
    -- Load the noice extension here so :Noice history is telescope-searchable
    require("telescope").load_extension("noice")
end)

