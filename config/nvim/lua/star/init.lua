-- =============================================================================
-- lua/star/init.lua - core settings
-- Loaded by init.lua via require("star"). Pulls in remaps, plugins, and the
-- runner, then sets all editor options.
-- =============================================================================

require("star.remap")   -- keybindings (see remap.lua)
require("star.packer")  -- plugin declarations (see packer.lua)
require("star.runner")  -- file runner keybinds (see runner.lua)

-- ── Colors ────────────────────────────────────────────────────────────────────
-- Enable 24-bit RGB color. Required for Catppuccin and most modern themes.
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

-- ── Format keybind ────────────────────────────────────────────────────────────
-- Ctrl+f: format the buffer. Uses LSP formatting if a server is attached,
-- falls back to gg=G (vim's built-in re-indent) otherwise.
-- Note: conform.lua also binds Ctrl+f — conform takes precedence when loaded.
vim.keymap.set("n", "<C-f>", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients > 0 then
        vim.lsp.buf.format({ async = true })
    else
        vim.cmd("normal gg=G")
    end
end, { noremap = true, silent = true })

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

-- ── Transparent background ────────────────────────────────────────────────────
-- Clear background highlights so the terminal's transparency shows through.
-- Covers the main editor area, inactive windows, nvim-tree, and lualine.
vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
vim.cmd([[hi NormalNC guibg=NONE ctermbg=NONE]])
vim.cmd([[hi NvimTreeNormal guibg=NONE]])
vim.cmd([[hi NvimTreeEndOfBuffer guibg=NONE]])
vim.cmd([[hi LualineNormal guibg=NONE]])
vim.cmd([[hi LualineInactive guibg=NONE]])
