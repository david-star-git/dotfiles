-- =============================================================================
-- lua/star/lazy.lua - plugin manager bootstrap (lazy.nvim)
--
-- Replaces packer.lua. packer.nvim is archived/unmaintained, and this config
-- picked up enough plugins (which-key, bufferline, a dashboard, gitsigns,
-- noice, ...) that real lazy-loading is worth having: most plugins now only
-- load on the event/command/keymap that actually needs them, so startup stays
-- fast instead of growing with every addition.
--
-- Individual plugin specs live in lua/star/plugins/*.lua — this file just
-- bootstraps lazy.nvim itself and points it at that directory.
--
-- Commands:
--   :Lazy         - open the plugin manager UI (install/update/clean/profile)
--   :Lazy sync    - install missing + update + clean removed plugins
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })

    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = { { import = "star.plugins" } },
    install = { colorscheme = { "macglass" } },
    checker = { enabled = false },
    change_detection = { notify = false },
    ui = {
        border = "rounded",
    },
    performance = {
        rtp = {
            -- Disable a few stock runtime plugins we never use, for a
            -- slightly faster startup.
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
                "netrwPlugin", -- nvim-tree replaces netrw entirely
            },
        },
    },
})
