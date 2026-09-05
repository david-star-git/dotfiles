-- =============================================================================
-- lua/star/plugins/dashboard.lua - start screen
--
-- New addition. Shows a quick-actions panel on startup instead of a blank
-- buffer — a small Launchpad-like touch, with the system green accent on the
-- selected action.
-- =============================================================================

return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        dashboard.section.header.val = {
            "                                                    ",
            " ██████╗ ██╗      █████╗ ███████╗███████╗           ",
            "██╔════╝ ██║     ██╔══██╗██╔════╝██╔════╝           ",
            "██║  ███╗██║     ███████║███████╗███████╗           ",
            "██║   ██║██║     ██╔══██║╚════██║╚════██║           ",
            "╚██████╔╝███████╗██║  ██║███████║███████║           ",
            " ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝           ",
            "                                                    ",
        }
        dashboard.section.header.opts.hl = "Title"

        dashboard.section.buttons.val = {
            dashboard.button("SPC SPC", "  Find file", ":lua require('telescope.builtin').find_files()<CR>"),
            dashboard.button("SPC g", "  Find git file", ":lua require('telescope.builtin').git_files()<CR>"),
            dashboard.button("SPC f", "  Grep string", ":lua require('telescope.builtin').grep_string({search = vim.fn.input('Grep > ')})<CR>"),
            dashboard.button("SPC e", "  File explorer", ":NvimTreeToggle<CR>"),
            dashboard.button("n", "  New file", ":enew<CR>"),
            dashboard.button("q", "  Quit", ":qa<CR>"),
        }
        for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts.hl = "@variable"
            button.opts.hl_shortcut = "WhichKey"
        end

        dashboard.section.footer.val = ""
        dashboard.opts.opts.noautocmd = true

        alpha.setup(dashboard.opts)
    end,
}
