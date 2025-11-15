vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-web-devicons").setup {
  default = true
}

-- Setup nvim-tree
require("nvim-tree").setup {
  disable_netrw = true,
  hijack_netrw = true,
  update_cwd = true,
  view = {
    width = 30,
    side = "left",
    float = {
      enable = true,
      quit_on_focus_loss = true,
      open_win_config = {
        relative = "editor",
        border = "rounded",       -- options: "single", "double", "rounded", "shadow", "none"
        width = 80,
        height = 40,
        row = math.floor((vim.o.lines - 40) / 2),   -- center vertically
        col = math.floor((vim.o.columns - 80) / 2) -- center horizontally
      },
    },
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
vim.api.nvim_set_hl(0, "VertSplit", { fg = "NONE", bg = "NONE" })


