-- =============================================================================
-- lua/star/plugins/which-key.lua - keybind hint popup
--
-- New addition. Pause after pressing <leader> (or any prefix) and a floating
-- panel lists what comes next — handy given how many custom leader bindings
-- this config has accumulated (test runner, git, LSP, buffers...).
-- =============================================================================

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        win = { border = "rounded" },
        icons = { mappings = false },
        spec = {
            { "<leader>b", group = "buffer" },
            { "<leader>t", group = "test" },
            { "<leader>r", group = "run" },
            { "<leader>c", group = "code" },
        },
    },
}
