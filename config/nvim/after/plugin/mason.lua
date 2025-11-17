
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "html",
    "cssls",
    "ts_ls",
    "pyright",
    "clangd",
    "jdtls",
  }
})

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(client, bufnr)
  local map = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
  end

  map("<leader>d", vim.lsp.buf.definition)
  map("K", vim.lsp.buf.hover)
  map("<leader>rn", vim.lsp.buf.rename)
  map("<leader>ca", vim.lsp.buf.code_action)
end

local servers = {
  "html",
  "cssls",
  "ts_ls",
  "pyright",
  "clangd",
  "jdtls",
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end
