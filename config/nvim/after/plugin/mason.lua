-- =============================================================================
-- after/plugin/mason.lua - LSP servers, formatters, linters
--
-- nvim 0.11+ / lspconfig v3: require("lspconfig").server.setup() is gone.
-- Servers are now configured via vim.lsp.config() and activated via
-- vim.lsp.enable(). mason-lspconfig's handlers table wires the two together.
-- =============================================================================

require("mason").setup()

-- mason-lspconfig only handles LSP servers.
-- Formatters and linters are installed separately via mason-tool-installer.
require("mason-lspconfig").setup(
{
    ensure_installed =
    {
        "cssls",
        "dockerls",
        "docker_compose_language_service",
        "html",
        "jdtls",
        "lua_ls",
        "neocmake",
        "pyright",
        "ts_ls",
        "vtsls",
        "yamlls",
    },
})

-- mason-tool-installer handles everything mason-lspconfig can't:
-- formatters, linters, and tools that aren't LSP servers.
require("mason-tool-installer").setup(
{
    ensure_installed =
    {
        -- Python
        "black",
        "blackd-client",
        "ruff",
        "pyright",
        -- C / C++ / CMake
        "clangd",
        "clang-format",
        "cmakelang",
        "cmakelint",
        -- Web / JS / TS
        "prettier",
        -- Lua
        "stylua",
        -- Shell
        "shfmt",
        -- Docker
        "hadolint",
        "djlint",
        -- SQL
        "sqlfluff",
        -- YAML
        "yamlls",
    },
    auto_update = true,
    run_on_start = true,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Shared on_attach — LSP keymaps that activate only when a server is running.
local on_attach = function(client, bufnr)
    local map = function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
    end
    map("<leader>d", vim.lsp.buf.definition)
    map("K",         vim.lsp.buf.hover)
    map("<leader>rn", vim.lsp.buf.rename)
    map("<leader>ca", vim.lsp.buf.code_action)
end

-- Apply shared defaults to every server via the wildcard config.
vim.lsp.config("*",
{
    capabilities = capabilities,
    on_attach    = on_attach,
})

-- lua_ls needs extra config to understand the nvim runtime environment.
-- Without this it warns on every vim.* call.
vim.lsp.config("lua_ls",
{
    settings =
    {
        Lua =
        {
            runtime    = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace  = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry  = { enable = false },
        },
    },
})

-- Activate all servers declared in ensure_installed above.
local servers =
{
    "cssls",
    "dockerls",
    "docker_compose_language_service",
    "html",
    "jdtls",
    "lua_ls",
    "neocmake",
    "pyright",
    "ts_ls",
    "vtsls",
    "yamlls",
}

for _, server in ipairs(servers) do
    vim.lsp.enable(server)
end
