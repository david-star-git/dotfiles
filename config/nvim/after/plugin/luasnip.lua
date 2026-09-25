-- =============================================================================
-- after/plugin/luasnip.lua - LuaSnip snippet engine
--
-- LuaSnip itself ships with no snippets. friendly-snippets is the actual
-- library - "for", "if", "func", "class", and so on, per language - in the
-- same VS Code JSON snippet format most editors already use, so it's a drop-
-- in library rather than something written from scratch. lazy_load() only
-- loads a given language's snippets the first time a buffer of that filetype
-- is opened, so this stays cheap even though the library covers dozens of
-- languages.
-- =============================================================================

require("luasnip.loaders.from_vscode").lazy_load()

