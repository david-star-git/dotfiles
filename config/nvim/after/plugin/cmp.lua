-- =============================================================================
-- after/plugin/cmp.lua - nvim-cmp completion engine
--
-- Completion is triggered and accepted manually with Alt keys so it never
-- interrupts typing. Sources are checked in order: LSP first, then open
-- buffer words, then filesystem paths.
-- =============================================================================

local cmp = require("cmp")

cmp.setup({
    mapping = {
        ["<M-n>"] = cmp.mapping.select_next_item(), -- Alt+n: next suggestion
        ["<M-p>"] = cmp.mapping.select_prev_item(), -- Alt+p: previous suggestion
        ["<M-y>"] = cmp.mapping.complete(), -- Alt+y: trigger completion menu
        ["<M-Space>"] = cmp.mapping.confirm({ select = true }), -- Alt+Space: accept top item
    },
    sources = {
        { name = "nvim_lsp" }, -- language server suggestions (highest priority)
        { name = "buffer" }, -- words from currently open buffers
        { name = "path" }, -- filesystem paths
    },
})
