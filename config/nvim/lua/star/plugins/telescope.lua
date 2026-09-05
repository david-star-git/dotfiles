-- =============================================================================
-- lua/star/plugins/telescope.lua - fuzzy finder
--
-- <leader><space> - find files in the current project
-- <leader>g        - find files tracked by git
-- <leader>f        - grep string across the project (prompts for input)
--
-- Styled like a centered Spotlight/Alfred panel rather than the default
-- full-width split — glass background + rounded border, matching the rest
-- of the macOS-inspired UI.
-- =============================================================================

return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader> ", function() require("telescope.builtin").find_files() end, desc = "Find files" },
        { "<leader>g", function() require("telescope.builtin").git_files() end, desc = "Git files" },
        {
            "<leader>f",
            function()
                require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
                require("telescope").load_extension("noice")
            end,
            desc = "Grep string",
        },
    },
    config = function()
        require("telescope").setup({
            defaults = {
                prompt_prefix = "  ",
                selection_caret = " ",
                -- "center" has no preview pane at all — prompt + results only,
                -- which is exactly the Spotlight/Alfred look we're going for.
                layout_strategy = "center",
                layout_config = {
                    center = { width = 0.6, height = 0.4 },
                },
                sorting_strategy = "ascending",
                border = true,
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                winblend = 12,
            },
        })
    end,
}
