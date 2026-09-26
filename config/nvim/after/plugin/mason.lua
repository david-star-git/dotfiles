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
        "clangd",
        "cssls",
        "dockerls",
        "docker_compose_language_service",
        "html",
        "jdtls",
        "lua_ls",
        "neocmake",
        "pyright",
        "vtsls",
        "yamlls",
    },
})

-- mason-tool-installer handles everything mason-lspconfig can't:
-- formatters, linters, and tools that aren't LSP servers. clangd itself
-- moved to mason-lspconfig above, since it IS an LSP server - it was
-- being installed here but never activated (see `servers` below), so it
-- sat on disk unused and C/C++ files had no LSP client at all: no
-- semantic completion, just buffer-word matching.
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

-- Shared on_attach - LSP keymaps that activate only when a server is running.
--
-- K, <leader>d, <leader>rn, and <leader>ca are routed through lspsaga.nvim's
-- floating-window UI instead of the plain vim.lsp.buf.* calls - same actions,
-- nicer presentation. See after/plugin/lspsaga.lua for the rest of its
-- keymaps (gh, gd, gl, [e/]e, <leader>o), which don't need an attached
-- client to be defined.
local on_attach = function(client, bufnr)
    local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
    local saga = function(lhs, cmd, desc)
        map(lhs, "<cmd>Lspsaga " .. cmd .. "<CR>", desc)
    end
    saga("<leader>d", "goto_definition", "Go to definition (Lspsaga)")
    saga("K", "hover_doc", "Hover doc (Lspsaga)")
    saga("<leader>rn", "rename", "Rename (Lspsaga)")
    saga("<leader>ca", "code_action", "Code action (Lspsaga)")

    -- Parameter hints in a small floating window while typing a call's
    -- arguments - which function you're in, which parameter you're on.
    require("lsp_signature").on_attach(
    {
        hint_enable = false, -- skip the virtual-text hint; the floating window alone is enough
        handler_opts = { border = "rounded" },
    }, bufnr)
end

-- Apply shared defaults to every server via the wildcard config.
vim.lsp.config("*",
{
    capabilities = capabilities,
    on_attach = on_attach,
})

-- lua_ls needs extra config to understand the nvim runtime environment.
-- Without this it warns on every vim.* call.
vim.lsp.config("lua_ls",
{
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

-- Activate all servers declared in ensure_installed above.
-- vtsls only, not ts_ls: running both against the same JS/TS buffer means
-- every completion, diagnostic, and hover result shows up twice, from two
-- separate servers both racing to answer the same request. vtsls wraps the
-- actual VS Code TypeScript extension, so it's the closer match for an
-- IDE-like completion experience; ts_ls is the older, plainer client.
local servers =
{
    "clangd",
    "cssls",
    "dockerls",
    "docker_compose_language_service",
    "html",
    "jdtls",
    "lua_ls",
    "neocmake",
    "pyright",
    "vtsls",
    "yamlls",
}

for _, server in ipairs(servers) do
    vim.lsp.enable(server)
end

