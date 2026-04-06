-- =============================================================================
-- lua/star/packer.lua - plugin declarations
--
-- Managed by Packer (wbthomason/packer.nvim).
-- After changing this file run :PackerSync to install/remove plugins.
--
-- Plugin configs live in after/plugin/*.lua — loaded automatically after all
-- plugins initialise, avoiding load-order issues.
-- =============================================================================

vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
    -- Packer manages itself
    use("wbthomason/packer.nvim")

    -- ── Fuzzy finder ──────────────────────────────────────────────────────────
    -- Telescope: file finder, live grep, git files, noice history browser.
    -- plenary.nvim is a required Lua utility library.
    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.0",
        requires = { { "nvim-lua/plenary.nvim" } },
    })

    -- ── Colorscheme ───────────────────────────────────────────────────────────
    -- Catppuccin Mocha — matches the terminal, tmux, GTK, and neomutt theme.
    use({ "catppuccin/nvim", as = "catppuccin" })

    -- ── Syntax highlighting ───────────────────────────────────────────────────
    -- Treesitter: fast, accurate syntax highlighting and code understanding.
    -- :TSUpdate keeps language grammars up to date.
    use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })

    -- ── UI enhancements ───────────────────────────────────────────────────────
    -- noice.nvim: replaces the cmdline, messages, and popupmenu with a modern
    -- floating UI. Requires nui.nvim (layout engine) and nvim-notify (toasts).
    use({
        "folke/noice.nvim",
        requires = { { "MunifTanjim/nui.nvim" }, { "rcarriga/nvim-notify" } },
    })

    -- lualine: fast and configurable statusline with git, diagnostics, mode.
    use({
        "nvim-lualine/lualine.nvim",
        requires = { "nvim-tree/nvim-web-devicons", opt = true },
    })

    -- nvim-web-devicons: file type icons used by lualine, nvim-tree, telescope.
    use("nvim-tree/nvim-web-devicons")

    -- nvim-tree: floating file explorer. Replaces netrw entirely.
    use({
        "nvim-tree/nvim-tree.lua",
        requires = "nvim-tree/nvim-web-devicons",
    })

    -- ── Tmux integration ──────────────────────────────────────────────────────
    -- vim-tmux-navigator: seamless movement between nvim splits and tmux panes.
    -- Alt+j/k/l/ö works identically inside and outside nvim.
    use({ "christoomey/vim-tmux-navigator" })

    -- ── Testing ───────────────────────────────────────────────────────────────
    -- vim-test: run nearest test, file, suite, or last test from inside nvim.
    -- vimux sends test output to a tmux pane instead of a new buffer.
    use({
        "vim-test/vim-test",
        requires = "preservim/vimux",
    })

    -- ── LSP + completion ──────────────────────────────────────────────────────
    -- mason: GUI installer for LSP servers, formatters, linters.
    -- mason-lspconfig: bridges mason with nvim-lspconfig for LSP servers.
    -- mason-tool-installer: extends mason to also manage formatters and linters
    --   that aren't LSP servers (black, stylua, prettier, clang-format, etc.).
    -- nvim-lspconfig: pre-configured setups for common language servers.
    use({
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "neovim/nvim-lspconfig",
    })

    -- nvim-cmp: completion engine.
    -- cmp-nvim-lsp: LSP candidates.
    -- cmp-buffer:   words from open buffers.
    -- cmp-path:     filesystem paths.
    use("hrsh7th/nvim-cmp")
    use("hrsh7th/cmp-nvim-lsp")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")

    -- ── Editing helpers ───────────────────────────────────────────────────────
    -- nvim-autopairs: auto-close brackets and quotes. Integrates with cmp so
    -- accepting a completion also closes any open pairs correctly.
    use("windwp/nvim-autopairs")

    -- nvim-ts-autotag: auto-close and auto-rename HTML/JSX/Vue tags using
    -- treesitter — smarter than regex-based solutions.
    use({
        "windwp/nvim-ts-autotag",
        requires = "nvim-treesitter/nvim-treesitter",
    })

    -- indent-blankline: rainbow indent guides with treesitter scope awareness.
    -- Each nesting level gets a different color from the rainbow palette.
    use("lukas-reineke/indent-blankline.nvim")

    -- conform.nvim: formatter runner. Maps filetypes to formatters and runs
    -- them on Ctrl+f. Configured in after/plugin/conform.lua.
    use({
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup()
        end,
    })

    -- ── Extras ────────────────────────────────────────────────────────────────
    -- presence.nvim: Discord Rich Presence showing current file and project.
    use("andweeb/presence.nvim")

    -- nvim-highlight-colors: inline color swatches for hex, rgb, hsl, tailwind.
    use("brenoprata10/nvim-highlight-colors")
end)
