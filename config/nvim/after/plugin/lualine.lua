-- =============================================================================
-- after/plugin/lualine.lua --lualine statusline
--
-- Status bar layout (left → right):
--   a: current mode
--   b: git branch, diff stats, LSP diagnostics
--   c: filename
--   x: encoding, file format, filetype
--   y: scroll percentage
--   z: cursor line:column
--
-- Inactive windows show only filename (c) and location (x).
-- Refreshes at ~60fps and on all relevant editor events.
-- =============================================================================

require("lualine").setup({
    options = {
        icons_enabled = true,
        theme = "auto", -- inherits from the active colorscheme
        -- Powerline-style separators matching the tmux theme
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = {}, winbar = {} },
        ignore_focus = {},
        always_divide_middle = true,
        always_show_tabline = true,
        globalstatus = false, -- per-window statuslines (not global)
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
            refresh_time = 16, -- ~60fps
            events = {
                "WinEnter",
                "BufEnter",
                "BufWritePost",
                "SessionLoadPost",
                "FileChangedShellPost",
                "VimResized",
                "Filetype",
                "CursorMoved",
                "CursorMovedI",
                "ModeChanged",
            },
        },
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
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {},
})
