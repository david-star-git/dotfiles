-- =============================================================================
-- lua/star/plugins/nvim-tree.lua - floating file explorer
--
-- nvim-tree replaces netrw entirely and opens as a centered floating window
-- (a glass panel, matching Telescope/noice). Git status is shown on files
-- and folders. Closing the explorer when opening a file is disabled so you
-- can open multiple files without reopening it.
--
-- Keybind: <leader>e toggles the explorer.
-- =============================================================================

return {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
        -- Must run before nvim-tree loads, or netrw racing it causes conflicts.
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,
    config = function()
        require("nvim-web-devicons").setup({ default = true })

        require("nvim-tree").setup({
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
                        border = "rounded",
                        width = 80,
                        height = 40,
                        row = math.floor((vim.o.lines - 40) / 2),
                        col = math.floor((vim.o.columns - 80) / 2),
                    },
                },
            },
            renderer = {
                highlight_git = true,
                icons = { show = { file = true, folder = true, git = true } },
            },
            git = { enable = true, ignore = false, timeout = 400 },
            actions = { open_file = { quit_on_open = false } },
        })
    end,
}
