require("star.remap")
require("star.packer")
require("star.runner")

vim.o.termguicolors = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Numbers
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

-- Tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.list = false
--vim.opt.listchars = { tab = "▸ ", trail = "·" }

-- Filetype-specific overrides
vim.api.nvim_create_autocmd("FileType", {
    pattern = "make",
    callback = function()
        vim.opt_local.expandtab = false -- Makefiles need real tabs
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
    end,
})

-- Map Ctrl-f to format buffer via LSP if available, otherwise fallback to gg=G
vim.keymap.set("n", "<C-f>", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 }) -- updated API
    if #clients > 0 then
        vim.lsp.buf.format({ async = true })
    else
        vim.cmd("normal gg=G")
    end
end, { noremap = true, silent = true })

vim.keymap.set("i", "<CR>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    if col >= 2 and line:sub(col - 1, col) == "{}" then
        return "<CR><Esc>O"
    else
        return "<CR>"
    end
end, { expr = true, noremap = true })

vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
vim.cmd([[hi NormalNC guibg=NONE ctermbg=NONE]])
vim.cmd([[hi NvimTreeNormal guibg=NONE]])
vim.cmd([[hi NvimTreeEndOfBuffer guibg=NONE]])
vim.cmd([[hi LualineNormal guibg=NONE]])
vim.cmd([[hi LualineInactive guibg=NONE]])
