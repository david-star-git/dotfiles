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
})
