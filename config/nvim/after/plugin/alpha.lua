-- =============================================================================
-- after/plugin/alpha.lua - project/startup dashboard
--
-- Opens when Neovim is started with a directory:
--     nvim .
-- =============================================================================

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

local bonsai_path = vim.fn.stdpath("config") .. "/bonsai.txt"

dashboard.section.header.val = vim.fn.readfile(bonsai_path)


dashboard.section.buttons.val =
{
    dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
    dashboard.button("g", "󰊢  Git files", ":Telescope git_files<CR>"),
    dashboard.button("s", "󰍉  Search", ":Telescope live_grep<CR>"),
    dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
    dashboard.button("q", "  Quit", ":qa<CR>"),

}

alpha.setup(dashboard.config)

vim.api.nvim_create_autocmd("VimEnter",
{
    callback = function()
        local args = vim.fn.argv()
        if #args == 0 then
            return
        end
        local target = args[1]
        if vim.fn.isdirectory(target) ~= 1 then
            return
        end
        -- Remove whatever nvim-tree/netrw created for the directory.
        vim.cmd("enew")
        -- Open Alpha in the now-empty window.
        vim.cmd("Alpha")
    end,
})

