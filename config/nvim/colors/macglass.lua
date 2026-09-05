-- =============================================================================
-- colors/macglass.lua - "macglass" colorscheme
--
-- A custom colorscheme (no external dependency) built around:
--   - Neutral macOS-style graphite backgrounds
--   - System Green as the one accent color (cursor, git, active states, focus)
--   - An Xcode-flavoured syntax palette (pink keywords, blue types, soft
--     mint-green strings) so code stays easy to scan
--   - A transparent editor background so kitty's blur/opacity shows through,
--     with floating windows (Telescope, LSP hover, nvim-tree, completion)
--     rendered as translucent "glass" panels via winblend/pumblend
--
-- Load with: vim.cmd.colorscheme("macglass")  (done in lua/star/theme.lua)
-- =============================================================================

vim.cmd("hi clear")

if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "macglass"

local p = require("star.palette")
local set = vim.api.nvim_set_hl

-- ── Editor surface ────────────────────────────────────────────────────────────
-- Normal/NormalNC stay transparent on purpose — this is what lets kitty's
-- background_blur/opacity show through the editor. Floating surfaces get a
-- real background + winblend so they read as frosted glass panels sitting on
-- top of that blur.
set(0, "Normal",        { fg = p.fg, bg = "NONE" })
set(0, "NormalNC",      { fg = p.fg, bg = "NONE" })
set(0, "NormalFloat",   { fg = p.fg, bg = p.bg_elevated })
set(0, "FloatBorder",   { fg = p.border, bg = p.bg_elevated })
set(0, "FloatTitle",    { fg = p.green, bg = p.bg_elevated, bold = true })
set(0, "EndOfBuffer",   { fg = p.bg, bg = "NONE" })
set(0, "NonText",       { fg = p.fg_disabled, bg = "NONE" })
set(0, "Conceal",       { fg = p.fg_muted })
set(0, "Whitespace",    { fg = p.fg_disabled })
set(0, "SpecialKey",    { fg = p.fg_disabled })

-- ── Cursor / lines ────────────────────────────────────────────────────────────
set(0, "Cursor",        { fg = p.bg, bg = p.green })
set(0, "CursorLine",    { bg = p.bg_highlight })
set(0, "CursorLineNr",  { fg = p.green, bold = true })
set(0, "LineNr",        { fg = p.fg_disabled })
set(0, "ColorColumn",   { bg = p.bg_highlight })
set(0, "Visual",        { bg = p.bg_selection })
set(0, "VisualNOS",     { bg = p.bg_selection })
set(0, "Search",        { bg = p.bg_search, fg = p.fg, bold = true })
set(0, "IncSearch",     { bg = p.green, fg = p.bg, bold = true })
set(0, "CurSearch",     { bg = p.green, fg = p.bg, bold = true })
set(0, "MatchParen",    { fg = p.green_bright, bold = true, underline = true })

-- ── Splits / borders / status ─────────────────────────────────────────────────
set(0, "WinSeparator",  { fg = p.border, bg = "NONE" })
set(0, "VertSplit",     { fg = p.border, bg = "NONE" })
set(0, "StatusLine",    { fg = p.fg, bg = "NONE" })
set(0, "StatusLineNC",  { fg = p.fg_muted, bg = "NONE" })
set(0, "TabLine",       { fg = p.fg_muted, bg = "NONE" })
set(0, "TabLineFill",   { bg = "NONE" })
set(0, "TabLineSel",    { fg = p.green, bg = "NONE", bold = true })
set(0, "SignColumn",    { bg = "NONE" })
set(0, "FoldColumn",    { fg = p.fg_disabled, bg = "NONE" })
set(0, "Folded",        { fg = p.fg_dim, bg = p.bg_elevated, italic = true })

-- ── Popup menu (completion, wildmenu) ─────────────────────────────────────────
set(0, "Pmenu",         { fg = p.fg, bg = p.bg_elevated })
set(0, "PmenuSel",      { fg = p.bg, bg = p.green, bold = true })
set(0, "PmenuSbar",     { bg = p.bg_elevated })
set(0, "PmenuThumb",    { bg = p.border_accent })
set(0, "PmenuBorder",   { fg = p.border, bg = p.bg_elevated })
set(0, "WildMenu",      { fg = p.bg, bg = p.green })

-- ── Diffs ─────────────────────────────────────────────────────────────────────
set(0, "DiffAdd",       { bg = p.bg_selection })
set(0, "DiffChange",    { bg = p.bg_highlight })
set(0, "DiffDelete",    { fg = p.red, bg = p.bg_dim })
set(0, "DiffText",      { bg = p.border, bold = true })

-- ── Messages / diagnostics ────────────────────────────────────────────────────
set(0, "ErrorMsg",      { fg = p.red, bold = true })
set(0, "WarningMsg",    { fg = p.yellow, bold = true })
set(0, "ModeMsg",       { fg = p.green, bold = true })
set(0, "Question",      { fg = p.green })

set(0, "DiagnosticError",          { fg = p.red })
set(0, "DiagnosticWarn",           { fg = p.yellow })
set(0, "DiagnosticInfo",           { fg = p.blue })
set(0, "DiagnosticHint",           { fg = p.teal })
set(0, "DiagnosticOk",             { fg = p.green })
set(0, "DiagnosticUnderlineError", { sp = p.red, undercurl = true })
set(0, "DiagnosticUnderlineWarn",  { sp = p.yellow, undercurl = true })
set(0, "DiagnosticUnderlineInfo",  { sp = p.blue, undercurl = true })
set(0, "DiagnosticUnderlineHint",  { sp = p.teal, undercurl = true })
set(0, "DiagnosticVirtualTextError", { fg = p.red, italic = true })
set(0, "DiagnosticVirtualTextWarn",  { fg = p.yellow, italic = true })
set(0, "DiagnosticVirtualTextInfo",  { fg = p.blue, italic = true })
set(0, "DiagnosticVirtualTextHint",  { fg = p.teal, italic = true })

-- ── Core syntax (legacy groups, still used by many filetypes/plugins) ────────
set(0, "Comment",       { fg = p.fg_muted, italic = true })
set(0, "String",        { fg = p.mint })
set(0, "Character",     { fg = p.mint })
set(0, "Number",        { fg = p.orange })
set(0, "Float",         { fg = p.orange })
set(0, "Boolean",       { fg = p.purple })
set(0, "Constant",      { fg = p.purple })
set(0, "Identifier",    { fg = p.fg })
set(0, "Function",      { fg = p.cyan })
set(0, "Statement",     { fg = p.pink })
set(0, "Conditional",   { fg = p.pink })
set(0, "Repeat",        { fg = p.pink })
set(0, "Label",         { fg = p.pink })
set(0, "Operator",      { fg = p.fg_dim })
set(0, "Keyword",       { fg = p.pink, italic = true })
set(0, "Exception",     { fg = p.pink })
set(0, "PreProc",       { fg = p.orange })
set(0, "Include",       { fg = p.pink })
set(0, "Define",        { fg = p.orange })
set(0, "Macro",         { fg = p.orange })
set(0, "Type",          { fg = p.blue })
set(0, "StorageClass",  { fg = p.purple, italic = true })
set(0, "Structure",     { fg = p.blue })
set(0, "Typedef",       { fg = p.blue })
set(0, "Special",       { fg = p.orange })
set(0, "SpecialChar",   { fg = p.orange })
set(0, "Tag",           { fg = p.pink })
set(0, "Delimiter",     { fg = p.fg_dim })
set(0, "Underlined",    { fg = p.blue, underline = true })
set(0, "Ignore",        { fg = p.fg_disabled })
set(0, "Todo",          { fg = p.bg, bg = p.yellow, bold = true })
set(0, "Title",         { fg = p.green, bold = true })
set(0, "Directory",     { fg = p.blue })

-- ── Treesitter captures ───────────────────────────────────────────────────────
set(0, "@variable",           { fg = p.fg })
set(0, "@variable.builtin",   { fg = p.purple, italic = true })
set(0, "@variable.parameter", { fg = p.fg })
set(0, "@variable.member",    { fg = p.fg_dim })
set(0, "@property",           { fg = p.fg_dim })
set(0, "@constant",           { fg = p.purple })
set(0, "@constant.builtin",   { fg = p.purple, italic = true })
set(0, "@string",             { fg = p.mint })
set(0, "@string.escape",      { fg = p.orange })
set(0, "@number",             { fg = p.orange })
set(0, "@boolean",            { fg = p.purple })
set(0, "@function",           { fg = p.cyan })
set(0, "@function.builtin",   { fg = p.cyan, italic = true })
set(0, "@function.call",      { fg = p.cyan })
set(0, "@function.macro",     { fg = p.orange })
set(0, "@method",             { fg = p.cyan })
set(0, "@method.call",        { fg = p.cyan })
set(0, "@constructor",        { fg = p.blue })
set(0, "@parameter",          { fg = p.fg, italic = true })
set(0, "@keyword",            { fg = p.pink, italic = true })
set(0, "@keyword.function",   { fg = p.pink, italic = true })
set(0, "@keyword.return",     { fg = p.pink, italic = true })
set(0, "@keyword.operator",   { fg = p.pink })
set(0, "@keyword.import",     { fg = p.pink })
set(0, "@conditional",        { fg = p.pink })
set(0, "@repeat",             { fg = p.pink })
set(0, "@type",               { fg = p.blue })
set(0, "@type.builtin",       { fg = p.blue, italic = true })
set(0, "@attribute",          { fg = p.orange })
set(0, "@namespace",          { fg = p.blue })
set(0, "@punctuation.bracket",{ fg = p.fg_dim })
set(0, "@punctuation.delimiter", { fg = p.fg_dim })
set(0, "@punctuation.special",{ fg = p.pink })
set(0, "@operator",           { fg = p.fg_dim })
set(0, "@comment",            { fg = p.fg_muted, italic = true })
set(0, "@tag",                { fg = p.pink })
set(0, "@tag.attribute",      { fg = p.orange, italic = true })
set(0, "@tag.delimiter",      { fg = p.fg_dim })
set(0, "@markup.heading",     { fg = p.green, bold = true })
set(0, "@markup.strong",      { fg = p.fg, bold = true })
set(0, "@markup.italic",      { fg = p.fg, italic = true })
set(0, "@markup.link",        { fg = p.blue, underline = true })
set(0, "@markup.list",        { fg = p.green })

-- ── LSP semantic tokens (fall back gracefully if unused) ─────────────────────
set(0, "@lsp.type.class",     { link = "Type" })
set(0, "@lsp.type.interface", { link = "Type" })
set(0, "@lsp.type.enum",      { link = "Type" })
set(0, "@lsp.type.parameter", { link = "@variable.parameter" })
set(0, "@lsp.type.property",  { link = "@variable.member" })

-- ── nvim-tree ─────────────────────────────────────────────────────────────────
set(0, "NvimTreeNormal",       { fg = p.fg, bg = p.bg_elevated })
set(0, "NvimTreeNormalNC",     { fg = p.fg, bg = p.bg_elevated })
set(0, "NvimTreeWinSeparator", { fg = p.border, bg = p.bg_elevated })
set(0, "NvimTreeEndOfBuffer",  { fg = p.bg_elevated, bg = p.bg_elevated })
set(0, "NvimTreeFolderIcon",   { fg = p.blue })
set(0, "NvimTreeFolderName",   { fg = p.fg })
set(0, "NvimTreeOpenedFolderName", { fg = p.green, bold = true })
set(0, "NvimTreeRootFolder",   { fg = p.green, bold = true })
set(0, "NvimTreeGitDirty",     { fg = p.yellow })
set(0, "NvimTreeGitNew",       { fg = p.green })
set(0, "NvimTreeGitDeleted",   { fg = p.red })
set(0, "NvimTreeIndentMarker", { fg = p.border })
set(0, "NvimTreeSpecialFile",  { fg = p.orange, underline = false })

-- ── Telescope (styled like a Spotlight / Alfred panel) ───────────────────────
set(0, "TelescopeNormal",        { fg = p.fg, bg = p.bg_elevated })
set(0, "TelescopeBorder",        { fg = p.border, bg = p.bg_elevated })
set(0, "TelescopePromptNormal",  { fg = p.fg, bg = p.bg_highlight })
set(0, "TelescopePromptBorder",  { fg = p.border_accent, bg = p.bg_highlight })
set(0, "TelescopePromptTitle",   { fg = p.bg, bg = p.green, bold = true })
set(0, "TelescopePreviewTitle",  { fg = p.bg, bg = p.blue, bold = true })
set(0, "TelescopeResultsTitle",  { fg = p.bg_elevated, bg = p.bg_elevated })
set(0, "TelescopeSelection",     { fg = p.fg, bg = p.bg_selection, bold = true })
set(0, "TelescopeMatching",      { fg = p.green, bold = true })
set(0, "TelescopePromptPrefix",  { fg = p.green })

-- ── which-key ─────────────────────────────────────────────────────────────────
set(0, "WhichKey",          { fg = p.green, bold = true })
set(0, "WhichKeyGroup",     { fg = p.blue })
set(0, "WhichKeyDesc",      { fg = p.fg })
set(0, "WhichKeySeparator", { fg = p.fg_disabled })
set(0, "WhichKeyFloat",     { bg = p.bg_elevated })
set(0, "WhichKeyBorder",    { fg = p.border, bg = p.bg_elevated })

-- ── gitsigns ──────────────────────────────────────────────────────────────────
set(0, "GitSignsAdd",          { fg = p.green })
set(0, "GitSignsChange",       { fg = p.orange })
set(0, "GitSignsDelete",       { fg = p.red })
set(0, "GitSignsChangedelete", { fg = p.orange })
set(0, "GitSignsTopdelete",    { fg = p.red })

-- ── indent guides ─────────────────────────────────────────────────────────────
set(0, "IndentGuide",      { fg = p.border })
set(0, "IndentGuideActive",{ fg = p.green })

-- ── bufferline ────────────────────────────────────────────────────────────────
set(0, "BufferLineFill",              { bg = "NONE" })
set(0, "BufferLineBackground",        { fg = p.fg_muted, bg = p.bg_dim })
set(0, "BufferLineBufferSelected",    { fg = p.fg, bg = p.bg_elevated, bold = true })
set(0, "BufferLineBufferVisible",     { fg = p.fg_dim, bg = p.bg_dim })
set(0, "BufferLineIndicatorSelected", { fg = p.green, bg = p.bg_elevated })
set(0, "BufferLineSeparator",         { fg = p.bg, bg = p.bg_dim })
set(0, "BufferLineSeparatorSelected", { fg = p.bg, bg = p.bg_elevated })
set(0, "BufferLineModified",          { fg = p.green, bg = p.bg_dim })
set(0, "BufferLineModifiedSelected",  { fg = p.green, bg = p.bg_elevated })
set(0, "BufferLineCloseButton",        { fg = p.fg_muted, bg = p.bg_dim })
set(0, "BufferLineCloseButtonSelected",{ fg = p.fg, bg = p.bg_elevated })

-- ── notify / noice ────────────────────────────────────────────────────────────
set(0, "NotifyBackground",     { bg = p.bg_elevated })
set(0, "NotifyINFOBorder",     { fg = p.blue })
set(0, "NotifyINFOTitle",      { fg = p.blue })
set(0, "NotifyINFOIcon",       { fg = p.blue })
set(0, "NotifyWARNBorder",     { fg = p.yellow })
set(0, "NotifyWARNTitle",      { fg = p.yellow })
set(0, "NotifyWARNIcon",       { fg = p.yellow })
set(0, "NotifyERRORBorder",    { fg = p.red })
set(0, "NotifyERRORTitle",     { fg = p.red })
set(0, "NotifyERRORIcon",      { fg = p.red })

-- ── highlight-colors virtual swatch background (transparent) ────────────────
set(0, "HighlightColorsInline", { bg = "NONE" })
