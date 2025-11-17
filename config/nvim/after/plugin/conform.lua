local conform = require("conform")

conform.formatters.clang_format = {
	append_args = { "-style=WebKit" },
}

conform.setup({
	formatters_by_ft = {
		python = { "black" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		java = { "clang_format" },
		html = { "prettier" },
		css = { "prettier" },
		scss = { "prettier" },
		less = { "prettier" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		lua = { "stylua" },
	},
})

vim.keymap.set("n", "<C-f>", function()
	conform.format({ async = true })
end, { noremap = true, silent = true })
