require("mason").setup()
-- mason-lspconfig only handles LSP servers.
-- Formatters and linters are installed separately via mason-tool-installer.
require("mason-lspconfig").setup(
{
    ensure_installed =
    {
        "cssls", -- CSS / SCSS
        "dockerls", -- Dockerfile
        "docker_compose_language_service", -- docker-compose.yml
        "html", -- HTML
        "jdtls", -- Java
        "lua_ls", -- Lua (covers nvim config)
        "neocmake", -- CMake (neocmakelsp)
        "pyright", -- Python type checking + completion
        "ts_ls", -- TypeScript / JavaScript
        "vtsls", -- Alternative TS server (vtsls)
        "yamlls", -- YAML
    },
})
-- mason-tool-installer handles everything mason-lspconfig can't:
-- formatters, linters, and tools that aren't LSP servers.
require("mason-tool-installer").setup(
{
    ensure_installed =
    {
        -- Python
        "black", -- formatter
        "blackd-client", -- connects to a running blackd daemon (faster black)
        "ruff", -- fast linter + formatter (replaces flake8/isort/etc.)
        "pyright", -- also listed here so the tool installer tracks it
        -- C / C++ / CMake
        "clangd", -- LSP
        "clang-format", -- formatter
        "cmakelang", -- CMake formatter (cmake-format)
        "cmakelint", -- CMake linter
        -- Web / JS / TS
        "prettier", -- formatter for JS/TS/HTML/CSS/JSON/Markdown/YAML
        -- Lua
        "stylua", -- formatter
        -- Shell
        "shfmt", -- formatter
        -- Docker
        "hadolint", -- Dockerfile linter
        "djlint", -- Django/Jinja/HTML template linter + formatter
        -- SQL
        "sqlfluff", -- linter + formatter (supports many SQL dialects)
        -- YAML
        "yamlls", -- also tracked here for completeness
    },
    auto_update = true,
    run_on_start = true,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
-- Shared on_attach — LSP keymaps that activate only when a server is running.
local on_attach = function(client, bufnr)
    local map = function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
    end
    map("<leader>d", vim.lsp.buf.definition)
    map("K", vim.lsp.buf.hover)
    map("<leader>rn", vim.lsp.buf.rename)
    map("<leader>ca", vim.lsp.buf.code_action)

end
-- Servers with default config
local servers =
{
    "cssls",
    "dockerls",
    "docker_compose_language_service",
    "html",
    "jdtls",
    "neocmake",
    "pyright",
    "ts_ls",
    "vtsls",
    "yamlls",
}

for _, server in ipairs(servers) do
    lspconfig[server].setup(
    {
        capabilities = capabilities,
        on_attach = on_attach,
    })
end
-- lua_ls needs extra config to understand the nvim runtime environment.
-- Without this it warns on every vim.* call.
lspconfig.lua_ls.setup(
{
    capabilities = capabilities,
    on_attach = on_attach,
    settings =
    {
        Lua =
        {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
        },
    },
})

