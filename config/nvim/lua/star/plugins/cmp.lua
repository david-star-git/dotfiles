-- =============================================================================
-- lua/star/plugins/cmp.lua - completion engine
--
-- Completion is triggered and accepted manually with Alt keys so it never
-- interrupts typing. Sources are checked in order: LSP first, then open
-- buffer words, then filesystem paths.
--
-- Alt+n / Alt+p - next / previous suggestion
-- Alt+y         - trigger completion menu
-- Alt+Space     - accept the selected item
-- =============================================================================

return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "windwp/nvim-autopairs",
    },
    config = function()
        local cmp = require("cmp")

        cmp.setup({
            mapping = {
                ["<M-n>"] = cmp.mapping.select_next_item(),
                ["<M-p>"] = cmp.mapping.select_prev_item(),
                ["<M-y>"] = cmp.mapping.complete(),
                ["<M-Space>"] = cmp.mapping.confirm({ select = true }),
            },
            sources = {
                { name = "nvim_lsp" },
                { name = "buffer" },
                { name = "path" },
            },
            window = {
                completion = cmp.config.window.bordered({ border = "rounded" }),
                documentation = cmp.config.window.bordered({ border = "rounded" }),
            },
        })

        -- Closing a pair automatically when a completion that ends with a
        -- function call is accepted.
        local ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
        if ok then
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end
    end,
}
