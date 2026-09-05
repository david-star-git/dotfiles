-- =============================================================================
-- lua/star/plugins/noice.lua - command line, messages, popup menu UI
--
-- Replaces the command line, messages, and popup menu with a modern floating
-- UI. LSP hover, signatures, and progress are also routed through noice.
--
-- Key behaviours:
--   - Search uses the classic bottom cmdline (bottom_search preset)
--   - Command palette floats in the centre (command_palette preset)
--   - Long messages open in a split instead of a tiny notification
--   - LSP progress shown as a small "mini" notification in the corner
-- =============================================================================

return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        {
            "rcarriga/nvim-notify",
            opts = {
                -- Background matches the glass panel color rather than a
                -- hardcoded hex, so it stays consistent if the palette ever
                -- changes.
                background_colour = require("star.palette").bg_elevated,
                render = "compact",
            },
        },
    },
    config = function()
        require("noice").setup({
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = true, -- glass-style border on hover/signature docs
            },
            routes = {
                filter = { event = "msg_showmode" },
                opts = { time = 500 },
            },
            messages = {
                enabled = true,
                view = "notify",
                view_error = "notify",
                view_warn = "notify",
                view_history = "messages",
                view_search = "virtualtext",
            },
            popupmenu = {
                enabled = true,
                backend = "nui",
                kind_icons = {},
            },
            lsp = {
                progress = {
                    enabled = true,
                    format = "lsp_progress",
                    format_done = "lsp_progress_done",
                    throttle = 1000 / 30,
                    view = "mini",
                },
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
                    ["vim.lsp.util.stylize_markdown"] = false,
                    ["cmp.entry.get_documentation"] = false,
                },
                hover = { enabled = true, silent = false, view = nil, opts = {} },
                signature = {
                    enabled = true,
                    auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 50 },
                    view = nil,
                    opts = {},
                },
                message = { enabled = true, view = "notify", opts = {} },
                documentation = {
                    view = "hover",
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
        })
    end,
}
