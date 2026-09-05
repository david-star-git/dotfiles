-- =============================================================================
-- lua/star/plugins/lualine.lua - statusline
--
-- Status bar layout (left → right):
--   a: current mode (a colored pill — green in normal mode, the system accent)
--   b: git branch, diff stats, LSP diagnostics
--   c: filename
--   x: encoding, file format, filetype
--   y: scroll percentage
--   z: cursor line:column
--
-- No powerline arrows — flat, minimal, transparent background so it reads as
-- part of the glass window rather than a separate opaque bar.
-- =============================================================================

return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local p = require("star.palette")

        local mode_colors = {
            normal = p.green,
            insert = p.blue,
            visual = p.purple,
            replace = p.red,
            command = p.orange,
            inactive = p.fg_muted,
        }

        local function pill(color)
            return { fg = p.bg, bg = color, gui = "bold" }
        end

        local theme = {
            normal = {
                a = pill(mode_colors.normal),
                b = { fg = p.fg_dim, bg = "NONE" },
                c = { fg = p.fg, bg = "NONE" },
            },
            insert = { a = pill(mode_colors.insert) },
            visual = { a = pill(mode_colors.visual) },
            replace = { a = pill(mode_colors.replace) },
            command = { a = pill(mode_colors.command) },
            inactive = {
                a = { fg = p.fg_muted, bg = "NONE" },
                b = { fg = p.fg_muted, bg = "NONE" },
                c = { fg = p.fg_muted, bg = "NONE" },
            },
        }

        require("lualine").setup({
            options = {
                icons_enabled = true,
                theme = theme,
                component_separators = "",
                section_separators = { left = "", right = "" },
                disabled_filetypes = { statusline = {}, winbar = {} },
                globalstatus = false,
                refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { "filename" },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
