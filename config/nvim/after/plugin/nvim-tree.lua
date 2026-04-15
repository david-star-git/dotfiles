-- =============================================================================
-- after/plugin/nvim-tree.lua - floating file explorer
--
-- nvim-tree replaces netrw entirely and opens as a centered floating window.
-- Git status is shown on files and folders. Closing the explorer when opening
-- a file is disabled so you can open multiple files without reopening it.
--
-- Keybind: <leader>e toggles the explorer.
-- =============================================================================
-- Disable netrw before nvim-tree loads — if netrw loads first it conflicts.

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- File type icons
require("nvim-web-devicons").setup({ default = true })

require("nvim-tree").setup(
{
    -- Replace netrw completely
    disable_netrw = true,
    hijack_netrw = true,
    -- Update the working directory when navigating into a folder
    update_cwd = true,
    view =
    {
        width = 30,
        side = "left",
        -- Open as a centered floating window instead of a side panel
        float =
        {
            enable = true,
            quit_on_focus_loss = true, -- close if you click outside
            open_win_config =
            {
                relative = "editor",
                border = "rounded",
                width = 80,
                height = 40,
                -- Center vertically and horizontally
                row = math.floor((vim.o.lines - 40) / 2),
                col = math.floor((vim.o.columns - 80) / 2),
            },
        },
    },
    renderer =
    {
        highlight_git = true, -- color files by git status
        icons =
        {
            show = { file = true, folder = true, git = true },
        },
    },
    git =
    {
        enable = true,
        ignore = false, -- show gitignored files (dimmed, not hidden)
        timeout = 400,
    },
    actions =
    {
        open_file =
        {
            quit_on_open = false, -- keep explorer open when opening files
        },
    },
})

-- Toggle the explorer
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

-- Hide the vertical split divider line between nvim-tree and the editor
vim.api.nvim_set_hl(0, "VertSplit", { fg = "NONE", bg = "NONE" })

