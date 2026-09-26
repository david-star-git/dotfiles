-- =============================================================================
-- after/plugin/gitsigns.lua - sign-column git markers
--
--   ]c / [c     next/previous hunk (falls back to vim's diff-mode ]c/[c
--               when actually in diff mode, so nothing is lost there)
--   <leader>hs  stage hunk                <leader>hr  reset hunk
--   <leader>hS  stage buffer              <leader>hR  reset buffer
--   <leader>hu  undo last stage           <leader>hp  preview hunk (float)
--   <leader>hb  blame current line        <leader>hB  toggle line blame
--   ih          "inner hunk" text object, e.g. dih deletes the hunk
--
-- (Toggle blame is <leader>hB, not <leader>tb - <leader>t is already
-- vim-test's "run nearest test", and <leader>t* would add a timeoutlen
-- delay to it.)
-- =============================================================================

require("gitsigns").setup(
{
    on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end
        -- Navigation - defers to vim's own ]c/[c while a diff view is open.
        map("n", "]c", function()
            if vim.wo.diff then
                return "]c"
            end
            vim.schedule(gs.next_hunk)
            return "<Ignore>"
        end, "Next hunk")
        map("n", "[c", function()
            if vim.wo.diff then
                return "[c"
            end
            vim.schedule(gs.prev_hunk)
            return "<Ignore>"
        end, "Previous hunk")
        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
        end, "Blame line")
        map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
        -- Text object: e.g. `dih` deletes the current hunk.
        map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
    end,
})

