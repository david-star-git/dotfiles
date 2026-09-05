-- =============================================================================
-- lua/star/plugins/bufferline.lua - buffer tabs
--
-- New addition. Renders open buffers as tabs across the top, macOS
-- Safari/Finder-tab style, with a green underline on the active buffer.
--
-- [b / ]b     - previous / next buffer
-- <leader>bp  - pick a buffer (jump-to-letter, like Mission Control)
-- <leader>bd  - close the current buffer
-- =============================================================================

return {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
        { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
        { "<leader>bp", "<cmd>BufferLinePick<CR>", desc = "Pick buffer" },
        { "<leader>bd", "<cmd>bdelete<CR>", desc = "Close buffer" },
    },
    opts = {
        options = {
            mode = "buffers",
            separator_style = "thin",
            always_show_bufferline = true,
            show_buffer_close_icons = true,
            show_close_icon = false,
            indicator = { style = "underline" },
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "Explorer",
                    highlight = "Directory",
                    separator = true,
                },
            },
        },
    },
}
