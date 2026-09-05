-- =============================================================================
-- lua/star/plugins/lsp.lua - LSP servers, formatters, linters
--
-- nvim 0.11+ / lspconfig v3: require("lspconfig").server.setup() is gone.
-- Servers are configured via vim.lsp.config() and activated via
-- vim.lsp.enable(). mason-lspconfig's setup wires the two together.
--
-- K          - hover docs
-- <leader>d  - go to definition
-- <leader>rn - rename symbol
-- <leader>ca - code action
-- =============================================================================

return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
        require("mason").setup({
            ui = { border = "rounded" },
        })

        -- mason-lspconfig only handles LSP servers. Formatters/linters are
        -- installed separately below via mason-tool-installer.
        require("mason-lspconfig").setup({
            ensure_installed = {
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

        -- Formatters, linters, and other tools that aren't LSP servers.
        -- (yamlls removed from this list — it's already an LSP server managed
        -- above by mason-lspconfig; listing it here too was redundant.)
        require("mason-tool-installer").setup({
            ensure_installed = {
                -- Python
                "black",
                "ruff",
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
            },
            auto_update = true,
            run_on_start = true,
        })

        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- LSP keymaps that activate only when a server is actually attached.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(ev)
                local map = function(lhs, rhs, desc)
                    vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
                end
                map("<leader>d", vim.lsp.buf.definition, "LSP: go to definition")
                map("K", vim.lsp.buf.hover, "LSP: hover")
                map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
                map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
            end,
        })

        -- Shared defaults applied to every server.
        vim.lsp.config("*", { capabilities = capabilities })

        -- lua_ls needs extra config to understand the nvim runtime, or it
        -- warns on every vim.* call.
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                    telemetry = { enable = false },
                },
            },
        })

        local servers = {
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
    end,
}
