-- =============================================================================
-- after/plugin/multicursor.lua - VS Code-style multiple cursors
--
-- multicursor.nvim ships no default keybinds at all, so every mapping below
-- is a deliberate choice. Uses <up>/<down> arrows (not j/k) so it's
-- unaffected by the jklö movement remap in remap.lua.
--
--   <up>/<down>          add a cursor above/below
--   <leader><up/down>    skip a line without adding a cursor
--   <leader>n / N        add a cursor on the next/previous match of the
--                        word (or visual selection) under the cursor
--   <leader>s / S        skip the next/previous match without adding one
--   <c-leftmouse>        add/remove a cursor by ctrl-clicking
--   <c-q>                toggle cursors on/off (only the main one moves)
--
-- Once you have 2+ cursors, a keymap "layer" activates on top of the above:
--   <left>/<right>       cycle which cursor is the "main" one
--   <leader>x            delete the main cursor
--   <esc>                enable cursors again, or clear them if already on
--
-- :h multicursor-nvim has many more actions (align columns, split/match by
-- regex, transpose selections, diagnostics-based cursors, etc.) if this
-- base set isn't enough.
-- =============================================================================

local mc = require("multicursor-nvim")
mc.setup()

local set = vim.keymap.set

set({ "n", "x" }, "<S-up>", function()
    mc.lineAddCursor(-1)
end)
set({ "n", "x" }, "<S-down>", function()
    mc.lineAddCursor(1)
end)
set({ "n", "x" }, "<leader><S-up>", function()
    mc.lineSkipCursor(-1)
end)
set({ "n", "x" }, "<leader><S-down>", function()
    mc.lineSkipCursor(1)
end)

set({ "n", "x" }, "<leader>n", function()
    mc.matchAddCursor(1)
end)
set({ "n", "x" }, "<leader>N", function()
    mc.matchAddCursor(-1)
end)
set({ "n", "x" }, "<leader>s", function()
    mc.matchSkipCursor(1)
end)
set({ "n", "x" }, "<leader>S", function()
    mc.matchSkipCursor(-1)
end)

set("n", "<c-leftmouse>", mc.handleMouse)
set("n", "<c-leftdrag>", mc.handleMouseDrag)
set("n", "<c-leftrelease>", mc.handleMouseRelease)

set({ "n", "x" }, "<c-q>", mc.toggleCursor)

-- Only active while multiple cursors exist, so these can't collide with
-- anything else in the config.
mc.addKeymapLayer(function(layerSet)
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
    layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
            mc.enableCursors()
        else
            mc.clearCursors()
        end
    end)
end)

-- Match the rest of the theme instead of the plugin's own defaults.
local hl = vim.api.nvim_set_hl
hl(0, "MultiCursorCursor", { reverse = true })
hl(0, "MultiCursorVisual", { link = "Visual" })
hl(0, "MultiCursorSign", { link = "SignColumn" })
hl(0, "MultiCursorMatchPreview", { link = "Search" })
hl(0, "MultiCursorDisabledCursor", { reverse = true })
hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })

