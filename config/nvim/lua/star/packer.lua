-- =============================================================================
-- lua/star/packer.lua - plugin declarations
--
-- Managed by Packer (wbthomason/packer.nvim).
-- After changing this file run :PackerSync to install/remove plugins.
--
-- Plugin configs live in after/plugin/*.lua - loaded automatically after all
-- plugins initialise, avoiding load-order issues.
-- =============================================================================
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
    -- Packer manages itself
    use("wbthomason/packer.nvim")
    -- ── Fuzzy finder ──────────────────────────────────────────────────────────
    -- Telescope: file finder, live grep, git files, noice history browser.
    -- plenary.nvim is a required Lua utility library.
    use(
    {
        "nvim-telescope/telescope.nvim",
        requires = { { "nvim-lua/plenary.nvim" } },
    })
    -- ── Colorscheme ───────────────────────────────────────────────────────────
    -- Catppuccin Mocha - matches the terminal, tmux, GTK, and neomutt theme.
    use({ "catppuccin/nvim", as = "catppuccin" })
    -- ── Syntax highlighting ───────────────────────────────────────────────────
    -- Treesitter: fast, accurate syntax highlighting and code understanding.
    -- :TSUpdate keeps language grammars up to date.
    use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
    -- ── UI enhancements ───────────────────────────────────────────────────────
    -- noice.nvim: replaces the cmdline, messages, and popupmenu with a modern
    -- floating UI. Requires nui.nvim (layout engine) and nvim-notify (toasts).
    use(
    {
        "folke/noice.nvim",
        requires = { { "MunifTanjim/nui.nvim" }, { "rcarriga/nvim-notify" } },
    })
    -- lualine: fast and configurable statusline with git, diagnostics, mode.
    use(
    {
        "nvim-lualine/lualine.nvim",
        requires = { "nvim-tree/nvim-web-devicons", opt = true },
    })
    -- nvim-web-devicons: file type icons used by lualine, nvim-tree, telescope.
    use("nvim-tree/nvim-web-devicons")
    -- nvim-tree: floating file explorer. Replaces netrw entirely.
    use(
    {
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
    use(
    {
        "vim-test/vim-test",
        requires = "preservim/vimux",
    })
    -- ── LSP + completion ──────────────────────────────────────────────────────
    -- mason: GUI installer for LSP servers, formatters, linters.
    -- mason-lspconfig: bridges mason with nvim-lspconfig for LSP servers.
    -- mason-tool-installer: extends mason to also manage formatters and linters
    --   that aren't LSP servers (black, stylua, prettier, clang-format, etc.).
    -- nvim-lspconfig: pre-configured setups for common language servers.
    use(
    {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "neovim/nvim-lspconfig",
    })
    -- nvim-cmp: completion engine.
    -- cmp-nvim-lsp:    LSP candidates (identifiers, members, the "." chain).
    -- cmp-buffer:      words from open buffers.
    -- cmp-path:        filesystem paths.
    -- lspkind:         icons per completion kind (function, variable, field...).
    -- lsp_signature:   parameter hints in a floating window while typing a call.
    -- LuaSnip:         snippet engine - "for" expanding into a full loop skeleton
    --                  with tab-stops, not just completing the word "for".
    -- friendly-snippets: the actual snippet library LuaSnip loads (for, if,
    --                  function, class, etc., per language) - LuaSnip itself
    --                  ships with no snippets of its own.
    -- cmp_luasnip:     puts LuaSnip's snippets in the completion menu.
    use("hrsh7th/nvim-cmp")
    use("hrsh7th/cmp-nvim-lsp")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")
    use("onsails/lspkind.nvim")
    use("ray-x/lsp_signature.nvim")
    use("L3MON4D3/LuaSnip")
    use("rafamadriz/friendly-snippets")
    use("saadparwaiz1/cmp_luasnip")
    -- ── Editing helpers ───────────────────────────────────────────────────────
    -- nvim-autopairs: auto-close brackets and quotes. Integrates with cmp so
    -- accepting a completion also closes any open pairs correctly.
    use("windwp/nvim-autopairs")
    -- nvim-ts-autotag: auto-close and auto-rename HTML/JSX/Vue tags using
    -- treesitter - smarter than regex-based solutions.
    use(
    {
        "windwp/nvim-ts-autotag",
        requires = "nvim-treesitter/nvim-treesitter",
    })
    -- indent-blankline: rainbow indent guides with treesitter scope awareness.
    -- Each nesting level gets a different color from the rainbow palette.
    use("lukas-reineke/indent-blankline.nvim")
    -- conform.nvim: formatter runner. Maps filetypes to formatters and runs
    -- them on Ctrl+f. Configured in after/plugin/conform.lua.
    use(
    {
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
    -- ── Treesitter extras ─────────────────────────────────────────────────────
    -- treesitter-context: sticky "scope" header (current function/class
    -- signature) pinned to the top of the window while scrolling.
    use(
    {
        "nvim-treesitter/nvim-treesitter-context",
        requires = "nvim-treesitter/nvim-treesitter",
    })
    -- treesitter-textobjects: syntax-aware text objects (af/if, ac/ic), jump
    -- to next/previous function or class, and swap parameters. main branch -
    -- matches the treesitter.lua config, which already moved off the old
    -- nvim-treesitter.configs module.
    use(
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        requires = "nvim-treesitter/nvim-treesitter",
    })
    -- rainbow-delimiters: alternating colors for nested brackets/parens,
    -- powered by treesitter. Purely visual, no keybinds.
    use("HiPhish/rainbow-delimiters.nvim")
    -- ── Multiple cursors ──────────────────────────────────────────────────────
    -- multicursor.nvim: add/remove cursors above, below, or on the next match,
    -- then edit normally. See after/plugin/multicursor.lua for keybinds.
    use({ "jake-stewart/multicursor.nvim", branch = "1.0" })
    -- ── Diagnostics / trouble list ────────────────────────────────────────────
    -- trouble.nvim: a pretty, navigable list for diagnostics, LSP references,
    -- symbols, quickfix, and the location list.
    use(
    {
        "folke/trouble.nvim",
        requires = "nvim-tree/nvim-web-devicons",
    })
    -- tiny-inline-diagnostic.nvim: renders diagnostics inline at the end of
    -- the line instead of vim's default virtual text - see after/plugin/
    -- tiny-inline-diagnostic.lua, which also turns the default text off.
    use("rachartier/tiny-inline-diagnostic.nvim")
    -- ── LSP UI ────────────────────────────────────────────────────────────────
    -- lspsaga.nvim: floating-window UI for hover, rename, code actions,
    -- definition peek, and a symbol outline - wraps the same LSP client
    -- mason.lua configures. See after/plugin/lspsaga.lua and the updated
    -- on_attach keymaps in after/plugin/mason.lua.
    use(
    {
        "nvimdev/lspsaga.nvim",
        branch = "main",
        requires =
        {
            "nvim-tree/nvim-web-devicons",
            "nvim-treesitter/nvim-treesitter",
        },
    })
    -- fidget.nvim: small corner notification for LSP progress (indexing,
    -- workspace symbols, etc). Replaces noice's built-in progress view - see
    -- the note in after/plugin/noice.lua.
    use("j-hui/fidget.nvim")
    -- ── Git ───────────────────────────────────────────────────────────────────
    -- gitsigns.nvim: sign-column markers for added/changed/removed lines,
    -- hunk stage/reset/preview, and line blame.
    use("lewis6991/gitsigns.nvim")
    -- zdiff.nvim: Zed-style multi-file diff viewer (uncommitted changes, or
    -- against any git ref) with treesitter highlighting in the diff itself.
    use("martindur/zdiff.nvim")
    -- ── Databases & docs ──────────────────────────────────────────────────────
    -- vim-dadbod (+ ui + completion): connect to and query databases from a
    -- drawer UI, with nvim-cmp completion for table/column names in sql
    -- buffers. See after/plugin/dadbod.lua.
    use("tpope/vim-dadbod")
    use(
    {
        "kristijanhusak/vim-dadbod-ui",
        requires = "tpope/vim-dadbod",
    })
    use(
    {
        "kristijanhusak/vim-dadbod-completion",
        requires = "tpope/vim-dadbod",
    })
    -- nvim-devdocs (ayoisaiah fork): browse devdocs.io documentation offline,
    -- filtered to the current buffer's filetype. The original luckasRanarison
    -- repo this was forked from is archived/unmaintained.
    use(
    {
        "ayoisaiah/nvim-devdocs",
        requires =
        {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    })
    -- nvim-hlslens: shows a match count/position (e.g. "[3/12]") next to
    -- search results while using / or ?.
    use("kevinhwang91/nvim-hlslens")
    -- ── Insert-mode helpers ───────────────────────────────────────────────────
    -- tabout.nvim: Tab jumps past the closing bracket/quote instead of
    -- inserting a literal tab. Must load after cmp (which also binds Tab).
    use(
    {
        "abecodes/tabout.nvim",
        wants = "nvim-treesitter",
        after = "nvim-cmp",
    })
    -- ── Discoverability ───────────────────────────────────────────────────────
    -- which-key.nvim: shows a popup of available keybindings when a prefix
    -- key (like <leader>) is held down.
    use("folke/which-key.nvim")
end)

