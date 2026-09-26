-- =============================================================================
-- after/plugin/which-key.lua - keybinding popup
--
-- Shows every available continuation of a key sequence (like <leader>) in a
-- popup after `timeoutlen` milliseconds. v3 API: `.add()` replaces the old
-- `.register()`, and most keymaps already carry their own `desc` (set at
-- the vim.keymap.set call itself, in whichever after/plugin/*.lua or
-- mason.lua on_attach defines them) - the groups below just label the
-- handful of <leader> prefixes with several children, so the popup shows
-- "Git Hunks" instead of nothing when you hold <leader>h.
-- =============================================================================

vim.o.timeout = true
vim.o.timeoutlen = 30000 -- delay before the popup appears; independent of this if you set `delay` below

local wk = require("which-key")

wk.setup(
{
    preset = "modern",
})

wk.add(
{
    { "<leader>r", group = "Run / Rename" }, -- rr/rd/rt/rc (runner.lua), rn (mason.lua)
    { "<leader>x", group = "Trouble" }, -- trouble.lua
    { "<leader>c", group = "Code" }, -- ca (mason.lua), cs/cl (trouble.lua)
    { "<leader>h", group = "Git Hunks" }, -- gitsigns.lua
    { "<leader>z", group = "Zdiff" }, -- zdiff.lua
    {
        "<leader>?",
        function()
            require("which-key").show({ global = false })
        end,
        desc = "Buffer-local keymaps",
    },
})

