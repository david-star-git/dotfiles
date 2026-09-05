-- =============================================================================
-- lua/star/plugins/conform.lua - formatting
--
-- <C-f> formats the current buffer.
--
-- Rewritten from the old hand-rolled reformatter. The previous version tried
-- to reimplement an entire formatter (import sorting, blank-line rules, HTML
-- class sorting, bracket-depth tracking...) in ~700 lines of pattern matching,
-- which is exactly the kind of thing that's fragile and quietly wrong on edge
-- cases. That's the "broken" part.
--
-- The fix: let real, battle-tested formatters do the actual formatting
-- (prettier, black, stylua, clang-format, djlint, shfmt — "sane defaults"),
-- and layer ONE small, focused pass on top that only moves opening braces
-- onto their own line ("Allman style, everywhere"). conform.nvim already
-- supports running formatters in sequence, so that's just:
--
--     formatters_by_ft.javascript = { "prettier", "allman_braces" }
--
-- Where a brace belongs to a block (if/for/while/function/class/try/catch)
-- it's moved to its own line. Where it's a value (object literal, import
-- list, destructuring) it's left exactly as prettier wrote it — turning
-- `const x = { a, b }` into four lines is not what "Allman braces" means.
-- Lua is simpler: `{}` is always a table constructor there (Lua blocks use
-- do/end, if/then/end — never braces), so every table literal gets the same
-- treatment.
--
-- C/C++/Java don't need a post-pass at all: clang-format's own
-- BreakBeforeBraces: Allman option already does exactly this, correctly,
-- including `else`/`catch`/`finally` on their own line.
-- =============================================================================

return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    keys = {
        {
            "<C-f>",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end,
            mode = "n",
            desc = "Format buffer (Allman braces)",
        },
    },
    cmd = { "ConformInfo" },
    config = function()
        local conform = require("conform")

        -- =========================================================================
        -- Allman brace pass — shared masking helper
        -- =========================================================================
        -- Language comment/string config, used only to blank out strings and
        -- comments before checking whether a line ends in an opening brace, so we
        -- never split a `{` that only appears inside a string or a comment.
        local LANG = {
            javascript = { line = "//", block = { "/*", "*/" }, quotes = { '"', "'", "`" } },
            typescript = { line = "//", block = { "/*", "*/" }, quotes = { '"', "'", "`" } },
            css        = { line = nil, block = { "/*", "*/" }, quotes = { '"', "'" } },
            scss       = { line = "//", block = { "/*", "*/" }, quotes = { '"', "'" } },
            lua        = { line = "--", block = { "--[[", "]]" }, quotes = { '"', "'" } },
        }

        -- mask: blank out string and comment contents on a single line so brace
        -- detection only ever looks at real code. Doesn't try to be a full
        -- lexer — formatted output from prettier/stylua is regular enough that a
        -- simple pass is reliable in practice.
        local function mask(line, cfg)
            local out = line

            -- Blank quoted strings first (handles both quote styles).
            for _, q in ipairs(cfg.quotes) do
                local pat = q .. "[^" .. q .. "]*" .. q
                out = out:gsub(pat, function(m)
                    return q .. string.rep(" ", #m - 2) .. q
                end)
            end

            -- Blank a trailing line comment.
            if cfg.line then
                local esc = cfg.line:gsub("(%W)", "%%%1")
                local s, e = out:find(esc)
                if s then
                    out = out:sub(1, s - 1) .. string.rep(" ", e - s + 1)
                end
            end

            return out
        end

        -- trailing_open_brace: true if `line` (once masked) ends in a real `{`
        -- that isn't immediately self-closed (i.e. not "...{}").
        local function trailing_open_brace(line, cfg)
            local masked = mask(line, cfg)
            local t = masked:match("^(.-)%s*$")
            return t ~= "" and t:sub(-1) == "{" and t ~= "{"
        end

        -- is_block_construct: does the text before the brace open a real block
        -- (if/for/while/function/class/try/catch/finally/do/arrow body) as
        -- opposed to a value position (object literal, import list,
        -- destructuring, type literal)? Only used for JS/TS/CSS — Lua has no
        -- such ambiguity since `{}` there is always a table.
        local function is_block_construct(before)
            before = before:match("^(.-)%s*$")
            -- Strip a trailing TS/Flow return-type annotation (": Foo<Bar[]> | Baz")
            -- so `function f(): Foo` / `render(): JSX.Element` still read as
            -- ending in a plain closing paren.
            before = before:gsub("%)%s*:%s*[%w_%.%[%]<>|&,%s]+$", ")")
            return before:match("%)$") ~= nil -- if (...) / for (...) / function(...) / method()
                or before:match("=>$") ~= nil -- arrow function body
                or before:match("^else$") ~= nil
                or before:match("}%s*else$") ~= nil
                or before:match("^try$") ~= nil
                or before:match("^do$") ~= nil
                or before:match("class%s") ~= nil -- `class Foo`, `export class Foo`
                or before:match("interface%s") ~= nil
                or before:match("namespace%s") ~= nil
                or before == "" -- bare `{` opening a block (e.g. CSS at-rule body)
        end

        -- split_chained_close: handles `} else {`, `} catch (e) {`, `} finally {`
        -- turning ONE line into three, each on its own line at the closer's indent:
        --   }
        --   else
        --   {
        local function split_chained_close(line, indent, cfg)
            local masked = mask(line, cfg)
            local middle = masked:match("^%s*}%s*(.-)%s*{%s*$")
            if not middle or middle == "" then
                return nil
            end
            -- Recover the un-masked middle text from the original line using the
            -- same span, so we keep original spacing/casing/args intact.
            local real_middle = line:match("^%s*}%s*(.-)%s*{%s*$")
            return {
                indent .. "}",
                indent .. real_middle,
                indent .. "{",
            }
        end

        -- allman_split: run the Allman pass over a buffer's lines for `lang`.
        local function allman_split(lines, lang)
            local cfg = LANG[lang]
            if not cfg then
                return lines
            end

            local out = {}
            local in_template = false -- inside a multi-line JS/TS template literal

            for _, line in ipairs(lines) do
                local indent = line:match("^(%s*)")

                -- Multi-line template literals (backticks) pass through verbatim —
                -- never rewrite anything inside one.
                if lang == "javascript" or lang == "typescript" then
                    if in_template then
                        table.insert(out, line)
                        local _, ticks = mask(line, cfg):gsub("`", "")
                        if ticks % 2 == 1 then
                            in_template = false
                        end
                        goto continue
                    end
                    local _, ticks = mask(line, cfg):gsub("`", "")
                    if ticks % 2 == 1 then
                        in_template = true
                    end
                end

                -- `} else {` / `} catch (e) {` / `} finally {` → three lines.
                local chained = split_chained_close(line, indent, cfg)
                if chained then
                    for _, l in ipairs(chained) do
                        table.insert(out, l)
                    end
                    goto continue
                end

                -- A plain trailing `{` → split into "before" + "{" on its own line,
                -- but only when it's actually opening a block (for lua, always).
                if trailing_open_brace(line, cfg) then
                    local masked = mask(line, cfg)
                    local brace_pos = masked:match("^.*()%{%s*$")
                    local before = line:sub(1, brace_pos - 1):match("^(.-)%s*$")
                    local before_trimmed = before:match("^%s*(.-)$")

                    -- CSS/SCSS braces are always block bodies (selectors, at-rules)
                    -- - unlike JS there's no "object literal" ambiguity, so every
                    -- rule opening gets split unconditionally, same as Lua tables.
                    local should_split = (lang == "lua" or lang == "css" or lang == "scss")
                        or is_block_construct(before_trimmed)

                    if should_split and before_trimmed ~= "" then
                        table.insert(out, before)
                        table.insert(out, indent .. "{")
                        goto continue
                    end
                end

                table.insert(out, line)
                ::continue::
            end

            return out
        end

        -- =========================================================================
        -- Universal tiny cleanup: em dash / en dash → hyphen-minus.
        -- These show up constantly in AI-generated text/docs but aren't valid in
        -- most code and cause headaches in terminals/diff tools.
        -- =========================================================================
        local function replace_dashes(lines)
            local out = {}
            for _, line in ipairs(lines) do
                line = line:gsub("\xE2\x80\x94", "-"):gsub("\xE2\x80\x93", "-")
                table.insert(out, line)
            end
            return out
        end

        local function buf_lines(bufnr)
            return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        end

        local function set_buf_lines(bufnr, lines)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            return lines
        end

        -- Register one "allman_<lang>" formatter per language that needs the
        -- post-pass. Each one just reads the buffer (already formatted by
        -- prettier/stylua, which conform runs immediately before this in the
        -- formatters_by_ft chain), applies the brace split + dash fix, writes it
        -- back.
        for lang, _ in pairs(LANG) do
            conform.formatters["allman_" .. lang] = {
                inherit = false,
                format = function(_, ctx)
                    local bufnr = ctx.buf
                    if not bufnr then
                        return {}
                    end
                    local lines = buf_lines(bufnr)
                    lines = allman_split(lines, lang)
                    lines = replace_dashes(lines)
                    return set_buf_lines(bufnr, lines)
                end,
            }
        end

        -- clang-format, forced to Allman brace style (native support — also puts
        -- else/catch/finally on their own line correctly, no post-pass needed).
        conform.formatters.clang_format_allman = {
            command = "clang-format",
            args = {
                "--style={BasedOnStyle: WebKit, BreakBeforeBraces: Allman, IndentWidth: 4}",
                "--stdin-filepath",
                "$FILENAME",
            },
            stdin = true,
        }

        conform.setup({
            formatters_by_ft = {
                -- Prettier does the real formatting; allman_* only repositions
                -- block braces afterwards.
                javascript = { "prettier", "allman_javascript" },
                typescript = { "prettier", "allman_typescript" },
                javascriptreact = { "prettier", "allman_javascript" },
                typescriptreact = { "prettier", "allman_typescript" },
                css              = { "prettier", "allman_css" },
                scss             = { "prettier", "allman_scss" },
                json             = { "prettier" },
                jsonc            = { "prettier" },
                yaml             = { "prettier" },
                markdown         = { "prettier" },

                -- stylua handles Lua's real formatting; allman_lua splits every
                -- table constructor `{` onto its own line (Lua has no block
                -- braces, so this is the only kind of `{` Lua ever has).
                lua = { "stylua", "allman_lua" },

                -- clang-format's Allman mode needs no post-pass.
                c    = { "clang_format_allman" },
                cpp  = { "clang_format_allman" },
                java = { "clang_format_allman" },

                -- Braces don't apply — these just get their real formatter.
                python = { "black" },
                html   = { "djlint" },
                sh     = { "shfmt" },
                bash   = { "shfmt" },
            },
            formatters = {
                djlint = {
                    prepend_args = { "--reformat", "--indent", "4" },
                },
                shfmt = {
                    prepend_args = { "-i", "4" },
                },
            },
        })
    end,
}
