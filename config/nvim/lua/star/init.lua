-- =============================================================================
-- lua/star/init.lua - core settings
-- Loaded by init.lua via require("star"). Pulls in remaps, the colorscheme,
-- plugins, and the runner, then sets all editor options.
-- =============================================================================

require("star.remap") -- keybindings (see remap.lua)
require("star.theme") -- macglass colorscheme + glass window options (see theme.lua)
require("star.lazy") -- plugin manager + plugin declarations (see lazy.lua, plugins/*.lua)
require("star.runner") -- file runner keybinds (see runner.lua)

-- ── Colors ────────────────────────────────────────────────────────────────────
-- Enable 24-bit RGB color. Required for the colorscheme (also set inside
-- colors/macglass.lua — harmless to set twice, kept here for clarity).
vim.o.termguicolors = true

-- ── Clipboard ─────────────────────────────────────────────────────────────────
-- Use the system clipboard for all yank/paste operations so text flows freely
-- between nvim and other applications.
vim.opt.clipboard = "unnamedplus"

-- ── Line numbers ──────────────────────────────────────────────────────────────
-- Show absolute line number on the current line and relative numbers elsewhere.
-- Relative numbers make jumping with e.g. 5k fast and intuitive.
vim.opt.number = true
vim.opt.relativenumber = true

-- Highlight only the line number of the cursor line, not the full line.
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

-- Always keep a sign column so gitsigns/diagnostics markers don't shift the
-- text horizontally when they appear.
vim.opt.signcolumn = "yes"

-- ── Indentation ───────────────────────────────────────────────────────────────
-- 4-space indentation, spaces not tabs, smart auto-indent.
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Whitespace character display is off by default. Uncomment listchars to show
-- tab arrows and trailing spaces when debugging indentation issues.
vim.opt.list = false
-- vim.opt.listchars = { tab = "▸ ", trail = "·" }

-- ── Windows / scrolling ───────────────────────────────────────────────────────
-- New splits open below/right, matching where most editors put them.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Keep 8 lines of context above/below the cursor.
vim.opt.scrolloff = 8

-- Smooth-scrolls over wrapped lines (built-in, nvim 0.10+). The animated
-- momentum feel for <C-d>/<C-u>/mouse wheel comes from neoscroll.nvim
-- (see plugins/neoscroll.lua) — this option covers a different case.
vim.opt.smoothscroll = true

-- ── Persistence ───────────────────────────────────────────────────────────────
-- Undo history survives closing and reopening a file.
vim.opt.undofile = true

-- React to CursorHold faster (LSP hover, gitsigns blame) without being so low
-- it fires constantly while typing.
vim.opt.updatetime = 250

-- which-key opens faster after pressing a prefix key like <leader>.
vim.opt.timeoutlen = 400

-- ── Filetype overrides ────────────────────────────────────────────────────────
-- Makefiles require real tabs — expandtab must be off or make will fail.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "make",
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- Lua uses 4-space indentation (explicit to override any plugin defaults).
vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
    end,
})

-- ── Smart Enter in insert mode ────────────────────────────────────────────────
-- If the cursor is between {} on Enter, expand them onto separate lines
-- (same behaviour as VS Code's auto-expand). Otherwise just insert a newline.
vim.keymap.set("i", "<CR>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    if col >= 2 and line:sub(col - 1, col) == "{}" then
        return "<CR><Esc>O"
    else
        return "<CR>"
    end
end, { expr = true, noremap = true })

-- Note on <C-f>: conform.lua registers the format keybind itself (via its
-- lazy.nvim `keys` spec, which is also what makes conform lazy-load the
-- first time you press it). It calls conform.format with
-- lsp_format = "fallback", which already does "use a registered formatter,
-- or fall back to the LSP's formatter if there isn't one" — the old manual
-- fallback-to-gg=G here would have raced against lazy's keymap depending on
-- load order, so it's gone; conform's own fallback covers the same case more
-- reliably.
