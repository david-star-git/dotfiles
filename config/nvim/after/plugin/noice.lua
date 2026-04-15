-- =============================================================================
-- after/plugin/noice.lua - noice.nvim UI overrides
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

require("noice").setup(
{
    -- ── Presets ───────────────────────────────────────────────────────────────
    presets =
    {
        bottom_search = true, -- / and ? use classic bottom cmdline
        command_palette = true, -- : cmdline + popupmenu float together
        long_message_to_split = true, -- :messages over a threshold go to a split
        inc_rename = false, -- we don't use inc-rename.nvim
        lsp_doc_border = false, -- no extra border on hover/signature docs
    },
    -- ── Message routing ───────────────────────────────────────────────────────
    routes =
    {
        -- Dismiss mode messages (INSERT, VISUAL, etc.) quickly
        filter = { event = "msg_showmode" },
        opts = { time = 500 },
    },
    -- ── Message views ─────────────────────────────────────────────────────────
    messages =
    {
        enabled = true,
        view = "notify", -- normal messages → toast notification
        view_error = "notify", -- errors → toast
        view_warn = "notify", -- warnings → toast
        view_history = "messages", -- :messages → built-in messages view
        view_search = "virtualtext", -- search count → inline virtual text
    },
    -- ── Popup menu ────────────────────────────────────────────────────────────
    popupmenu =
    {
        enabled = true,
        backend = "nui", -- nui.nvim renders the completion popup
        kind_icons = {},
    },
    -- ── LSP integration ───────────────────────────────────────────────────────
    lsp =
    {
        -- Show LSP progress (indexing, formatting) as a small corner notification.
        progress =
        {
            enabled = true,
            format = "lsp_progress",
            format_done = "lsp_progress_done",
            throttle = 1000 / 30, -- update at 30fps max
            view = "mini",
        },
        -- Don't override markdown rendering — let the LSP handle it directly.
        override =
        {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
            ["vim.lsp.util.stylize_markdown"] = false,
            ["cmp.entry.get_documentation"] = false,
        },
        -- Hover docs (K key)
        hover =
        {
            enabled = true,
            silent = false,
            view = nil,
            opts = {},
        },
        -- Signature help — shown automatically when typing function arguments.
        signature =
        {
            enabled = true,
            auto_open =
            {
                enabled = true,
                trigger = true, -- show on trigger characters (e.g. "(" )
                luasnip = true,
                throttle = 50,
            },
            view = nil,
            opts = {},
        },
        -- General LSP messages (e.g. server status)
        message =
        {
            enabled = true,
            view = "notify",
            opts = {},
        },
        -- Hover and signature doc rendering options
        documentation =
        {
            view = "hover",
            opts =
            {
                lang = "markdown",
                replace = true,
                render = "plain",
                format = { "{message}" },
                win_options = { concealcursor = "n", conceallevel = 3 },
            },
        },
    },
})

