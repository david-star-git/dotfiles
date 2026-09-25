-- =============================================================================
-- after/plugin/cmp.lua - nvim-cmp completion engine
--
-- The menu pops up on its own as you type (nvim-cmp's own default); the Alt
-- keys below are for manually forcing it open, cycling items, and accepting
-- one. Sources are grouped so LSP results and snippets always come first:
-- buffer words and filesystem paths only show up when those have nothing to
-- offer, instead of competing with real suggestions on every keystroke.
-- lspkind labels each item with what kind of thing it is (function,
-- variable, field, snippet, ...).
--
-- LuaSnip is the snippet engine, handling two different sources of
-- placeholder-style completions: a language server's own snippet-style
-- completions (a function call with its parameters filled in as
-- placeholders), and LuaSnip's own snippet library (typing "for" and
-- getting a full loop skeleton, tab-stops included, instead of just the
-- word "for" completed). <Tab> / <Shift-Tab> jump forward and backward
-- between those placeholders once a snippet is expanded, and fall back to
-- an ordinary tab/shift-tab the rest of the time - they're deliberately
-- separate from the Alt-key mappings below, which are only ever about the
-- completion menu itself.
-- =============================================================================

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup(
{
    snippet =
    {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping =
    {
        ["<M-n>"] = cmp.mapping.select_next_item(), -- Alt+n: next suggestion
        ["<M-p>"] = cmp.mapping.select_prev_item(), -- Alt+p: previous suggestion
        ["<M-y>"] = cmp.mapping.complete(), -- Alt+y: trigger completion menu
        ["<M-Space>"] = cmp.mapping.confirm({ select = true }), -- Alt+Space: accept top item
        ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    },
    sources = cmp.config.sources(
    {
        { name = "nvim_lsp" }, -- language server suggestions
        { name = "luasnip" }, -- snippet library (for, if, func, ...)
    },
    {
        { name = "buffer" }, -- words from currently open buffers
        { name = "path" }, -- filesystem paths
    }),
    formatting =
    {
        format = require("lspkind").cmp_format(
        {
            mode = "symbol_text",
            maxwidth = 50,
        }),
    },
})

