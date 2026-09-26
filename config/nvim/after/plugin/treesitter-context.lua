-- =============================================================================
-- after/plugin/treesitter-context.lua - sticky scope header
--
-- Pins the enclosing function/class/block signature to the top of the
-- window while you scroll down inside it, so you never lose track of which
-- function you're in.
-- =============================================================================

require("treesitter-context").setup(
{
    max_lines = 3, -- cap how tall the sticky header can get
    multiline_threshold = 1, -- collapse multi-line signatures to one line
    trim_scope = "outer", -- prefer showing the outermost enclosing scope first
    mode = "cursor", -- context is based on the cursor position
})

-- No keybind here: <leader>t is already vim-test's "run nearest test", and
-- <leader>t<anything> would add a timeoutlen delay to that binding. Use
-- :TSContext jump_to_context if you want to hop to the top of the context.

