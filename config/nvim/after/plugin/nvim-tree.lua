vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-web-devicons").setup {
  default = true
}

-- Setup nvim-tree
require("nvim-tree").setup {
  disable_netrw = true,
  hijack_netrw = true,
  open_on_setup = false,
  update_cwd = true,
  view = {
    width = 30,
    side = "left",
    mappings = {
      list = {
        { key = {"<CR>", "o"}, action = "edit" },
        { key = "v", action = "vsplit" },
        { key = "h", action = "split" },
        { key = "r", action = "refresh" },
        { key = "a", action = "create" },
        { key = "d", action = "remove" },
        { key = "R", action = "rename" },
      }
    }
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        file = true,
        folder = true,
        git = true,
      },
    },
  },
  git = {
    enable = true,
    ignore = false,
    timeout = 400,
  },
  actions = {
    open_file = {
      quit_on_open = false,
    },
  },
}

-- Keymap to toggle nvim-tree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

