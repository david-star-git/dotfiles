-- =============================================================================
-- after/plugin/treesitter-textobjects.lua - syntax-aware text objects
--
-- main branch API: as of nvim-treesitter-textobjects 1.0+, there is no more
-- `require('nvim-treesitter.configs').setup { textobjects = ... }` module -
-- each feature (select/move/swap) is wired up with plain vim.keymap.set
-- calls, matching how treesitter.lua already configures nvim-treesitter
-- itself.
--
--   Select:  af/if function, ac/ic class
--   Move:    ]m [m next/prev function start, ]] [[ next/prev class start
--            ]M [M / ][ [] the matching *end* variants
--   Swap:    <leader>p / <leader>P - swap the current function parameter
--            with the next / previous one
--   Repeat:  ; and , repeat the last move (and still work for f/F/t/T)
-- =============================================================================

vim.g.no_plugin_maps = true -- don't let built-in ftplugins claim these keys first

local move = require("nvim-treesitter-textobjects.move")
local select = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")
local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

require("nvim-treesitter-textobjects").setup(
{
    select = { lookahead = true }, -- jump forward to the textobj if not on it yet
    move = { set_jumps = true }, -- record jumps so <C-o>/<C-i> can undo a move
})


-- ── Select ────────────────────────────────────────────────────────────────────
local function map_select(keys, capture)
    vim.keymap.set({ "x", "o" }, keys, function()
        select.select_textobject(capture, "textobjects")
    end)
end

map_select("af", "@function.outer")
map_select("if", "@function.inner")
map_select("ac", "@class.outer")
map_select("ic", "@class.inner")
map_select("aa", "@parameter.outer")
map_select("ia", "@parameter.inner")


-- ── Move ──────────────────────────────────────────────────────────────────────
local function map_move(keys, fn, capture)
    vim.keymap.set({ "n", "x", "o" }, keys, function()
        fn(capture, "textobjects")
    end)
end

map_move("]m", move.goto_next_start, "@function.outer")
map_move("]]", move.goto_next_start, "@class.outer")
map_move("]M", move.goto_next_end, "@function.outer")
map_move("][", move.goto_next_end, "@class.outer")
map_move("[m", move.goto_previous_start, "@function.outer")
map_move("[[", move.goto_previous_start, "@class.outer")
map_move("[M", move.goto_previous_end, "@function.outer")
map_move("[]", move.goto_previous_end, "@class.outer")

-- ── Swap ──────────────────────────────────────────────────────────────────────
-- <leader>a/<leader>s are already taken (vim-test suite, multicursor match
-- skip), so parameter swap lives on <leader>p / <leader>P instead.
vim.keymap.set("n", "<leader>p", function()
    swap.swap_next("@parameter.inner")
end, { desc = "Swap parameter with next" })
vim.keymap.set("n", "<leader>P", function()
    swap.swap_previous("@parameter.inner")
end, { desc = "Swap parameter with previous" })

-- ── Repeat with ; and , ───────────────────────────────────────────────────────
-- ; always goes forward and , always goes backward, regardless of which
-- direction the last move was. f/F/t/T are wired in too so they stay
-- repeatable with ; and , exactly as before.
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

