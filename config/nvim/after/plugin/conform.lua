-- =============================================================================
-- after/plugin/conform.lua - conform.nvim formatter configuration
--
-- Two formatting modes:
--   Ctrl+F       - Allman style (opening brace on its own line)
--   Ctrl+Shift+F - Standard K&R style (opening brace on same line)
--
-- Supported languages and their formatters:
--   lua                                     - stylua + post-processor
--   javascript, typescript                  - prettier + post-processor
--   css                                     - prettier + post-processor
--   python                                  - black + post-processor
--   c, cpp, java                            - clang-format + post-processor
--   html                                    - djlint + post-processor
--
-- Every language above is reindented from scratch by a real external
-- formatter first (so a file is fully reformatted no matter how cursed its
-- existing indentation is), then - for lua/js/ts/css only - a small Lua
-- rewriter relocates the opening "{" onto its own line for the Allman
-- variant, and finally every language passes through the same universal
-- post-processor below. Required external tools: stylua, prettier,
-- clang-format, black, djlint.
--
-- Universal post-processor passes (in order):
--   0.  Em dash and en dash replaced with hyphen-minus (-)
--   1.  Tabs expanded to 4 spaces, trailing whitespace trimmed, CR stripped
--   2.  Imports sorted alphabetically within each blank-line-separated group
--   3a. HTML tag attributes sorted alphabetically and stacked vertically
--   3.  HTML class attributes sorted alphabetically and stacked vertically
--   4.  Blank-line spacing rules (see detailed notes in the function body)
--   4b. Header comment: exactly one blank line after the opening comment block
--   4c. Python: one blank line after a standalone closing bracket line
--       (a line that is only ), }, or ] with no trailing comma)
--   4d. CSS: one blank line before any declaration line that has an inline comment
--   5.  Collapse 3+ consecutive blank lines to at most 2
--   6.  Strip leading blank lines from the file
--   7.  Exactly one trailing newline
--
-- Idempotency guarantee: formatting an already-formatted file produces no change.
--
-- What is NEVER modified:
--   - Comment text (-- / // / # / /* */ / <!-- -->)
--   - Multi-line string / docstring content (""" / ''' / [[ ]])
--   - Anything inside an unclosed ( or [ (a wrapped call or array literal).
--     { and } are code-block delimiters, not expression brackets, and are
--     deliberately NOT tracked here - see count_net_brackets below for why.
-- =============================================================================

local conform = require("conform")


-- =============================================================================
-- Low-level helpers
-- =============================================================================
-- split_lines: split a shell command's stdout into a table of lines,
-- preserving blank lines (an empty line is a real, meaningful line - it must
-- not just vanish). Returns {} for a truly empty string so callers can tell
-- "the tool produced nothing" apart from "the tool produced one blank line".
local function split_lines(text)
    if text == "" then return {} end

    local out    = {}
    local normalized = text:gsub("\r\n", "\n"):gsub("\r", "\n")

    for s in (normalized .. "\n"):gmatch("(.-)\n") do
        table.insert(out, s)
    end

    return out
end


-- run_cmd_on_buf: pipe the buffer through an external shell command and return
-- the result as a table of lines. Falls back to the original lines on failure.
local function run_cmd_on_buf(bufnr, cmd_parts)
    local lines   = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")

    -- Every argument is shell-escaped individually here so callers never
    -- have to (and never have to worry about it). Without this, any arg
    -- containing spaces - e.g. a clang-format --style="{...}" spec - gets
    -- word-split by the shell into several bogus arguments instead of
    -- staying one.
    local escaped_parts = {}

    for _, part in ipairs(cmd_parts) do
        table.insert(escaped_parts, vim.fn.shellescape(part))
    end

    -- `printf '%s'` rather than `echo`: /bin/sh's echo builtin (dash, on
    -- Ubuntu/Debian) interprets backslash escapes by default, so any source
    -- line containing \n, \t, \\, etc. inside a string literal - i.e. almost
    -- any real C/Python/JS/Lua file - would get silently mangled (a real "\n"
    -- turned into an actual newline) before the formatter ever saw it.
    -- printf's %s argument is never escape-processed, so content survives
    -- byte-for-byte.
    local handle = io.popen(
        "printf '%s\\n' " .. vim.fn.shellescape(content)
        .. " | " .. table.concat(escaped_parts, " ")
    )

    if not handle then
        return lines
    end

    local result = handle:read("*a")
    handle:close()

    local out = split_lines(result)

    return #out > 0 and out or lines
end


-- apply_to_buf: write a table of lines into the buffer and return them.
local function apply_to_buf(bufnr, lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    return lines
end


-- =============================================================================
-- Line classification helpers
-- =============================================================================
local function is_blank(line)
    return line:match("^%s*$") ~= nil
end


-- is_comment: true for single-line comment starters in any supported language.
-- Docstrings (""" / ''' / [[ ]]) are handled separately as multi-line strings
-- so that their internal content is never touched.
local function is_comment(line)
    local t = line:match("^%s*(.-)%s*$")

    return t:match("^//")
        or t:match("^#[^!]")   -- # but not shebang (#!)
        or t:match("^%-%-")
        or t:match("^/%*")
        or t:match("^%*")      -- continuation lines inside /* ... */
        or t:match("^<!%-%-")
        or false

end


local function indent_of(line)
    local s = line:match("^(%s*)")

    return s and #s or 0
end


local function trimmed(line)
    return line:match("^%s*(.-)%s*$")
end


-- is_top_level_def: a function or class definition at indent level 0.
local function is_top_level_def(line, lang)
    if is_comment(line) then return false end

    if indent_of(line) ~= 0 then return false end

    local t = trimmed(line)

    if lang == "lua" then
        return t:match("^function%s") ~= nil
            or t:match("^local%s+function%s") ~= nil
            -- A top-level dotted-name assignment whose value is clearly a
            -- substantial definition - a function, a table literal on the
            -- same line, or a bare trailing "=" whose value continues on the
            -- next line (this file's own own style: "name =" then "{" on the
            -- line after) - such as this file's own
            -- conform.formatters.css_standard = { ... } blocks. Deliberately
            -- narrower than "any dotted assignment": a plain one-liner
            -- setting like  vim.opt.number = true  has a real scalar value
            -- immediately after "=" on the same line, so it matches none of
            -- these three shapes and is left alone - forcing 2 blank lines
            -- between every vim.opt.x = y / vim.g.x = y line in an ordinary
            -- init.lua would be exactly the unwanted churn this file exists
            -- to avoid.
            or t:match("^[%w_][%w_]*%.[%w_%.]+%s*=%s*function%f[%A]") ~= nil
            or t:match("^[%w_][%w_]*%.[%w_%.]+%s*=%s*{%s*$") ~= nil
            or t:match("^[%w_][%w_]*%.[%w_%.]+%s*=%s*$") ~= nil
    end

    if lang == "javascript" or lang == "typescript" then
        return t:match("^function%s") ~= nil
            or t:match("^async%s+function%s") ~= nil
            or t:match("^class%s") ~= nil
            or t:match("^export%s+function") ~= nil
            or t:match("^export%s+async%s+function") ~= nil
            or t:match("^export%s+class") ~= nil
            or t:match("^export%s+default") ~= nil
            or t:match("^const%s+%w+%s*=.*function") ~= nil
            or t:match("^const%s+%w+%s*=.*=>") ~= nil

    end

    if lang == "python" then
        return t:match("^def%s") ~= nil
            or t:match("^class%s") ~= nil
            or t:match("^async%s+def%s") ~= nil
    end

    if lang == "c" or lang == "cpp" then
        return t:match("^[%w_][%w_%s%*&:<>]+%(") ~= nil
            and not t:match("^if%s*%(")
            and not t:match("^while%s*%(")
            and not t:match("^for%s*%(")
            and not t:match("^switch%s*%(")
            and not t:match("^return")
            and not t:match(";%s*$")   -- forward declarations / calls, not defs
            and not t:match(",%s*$")   -- multi-line call continuation

    end

    if lang == "java" then
        return t:match("^[%w%s]-class%s+%a") ~= nil
            or t:match("^[%w%s]-interface%s+%a") ~= nil
            or t:match("^[%w%s]-enum%s+%a") ~= nil
    end

    return false
end


-- is_method_def: a function or method definition at indent > 0.
local function is_method_def(line, lang)
    if is_comment(line) then return false end

    if indent_of(line) == 0 then return false end

    local t = trimmed(line)

    if lang == "lua" then
        return t:match("^function%s") ~= nil
            or t:match("^local%s+function%s") ~= nil
    end

    if lang == "javascript" or lang == "typescript" then
        return t:match("^function%s") ~= nil
            or t:match("^async%s+function%s") ~= nil
            or t:match("^const%s+%w+%s*=.*=>") ~= nil
            or (t:match("^%w+%s*%(.*%)%s*{?$") ~= nil
                and not t:match("^if%s*%(")
                and not t:match("^while%s*%(")
                and not t:match("^for%s*%(")
                and not t:match("^switch%s*%(")
                and not t:match("^catch%s*%("))
    end

    if lang == "python" then
        return t:match("^def%s") ~= nil
            or t:match("^async%s+def%s") ~= nil
    end

    if lang == "c" or lang == "cpp" or lang == "java" then
        -- Same signature shape as the top-level c/cpp check, plus the
        -- exclusions that matter far more here: at indent > 0 this pattern
        -- would otherwise match nearly every plain function CALL too
        -- ("doSomething(x, y);"), since a call and a definition look
        -- identical minus the trailing ";" / "," and the body brace.
        return t:match("^[%w_][%w_%s%*&:<>%[%]]+%(") ~= nil
            and not t:match("^if%s*%(")
            and not t:match("^while%s*%(")
            and not t:match("^for%s*%(")
            and not t:match("^switch%s*%(")
            and not t:match("^return")
            and not t:match("^new%s")
            and not t:match(";%s*$")
            and not t:match(",%s*$")
    end

    return false
end


-- is_import: import / require / include lines used for alphabetical sorting.
local function is_import(line, lang)
    local t = trimmed(line)

    if lang == "lua" then
        return t:match("^local%s+%w+%s*=%s*require") ~= nil
            or t:match("^require%s*%(") ~= nil
    end

    if lang == "javascript" or lang == "typescript" then
        return t:match("^import%s") ~= nil
            or t:match("^const%s+%w+%s*=%s*require") ~= nil
    end

    if lang == "python" then
        return t:match("^import%s") ~= nil
            or t:match("^from%s+%S+%s+import") ~= nil
    end

    if lang == "c" or lang == "cpp" then
        return t:match("^#include") ~= nil
    end

    if lang == "java" then
        return t:match("^import%s") ~= nil
    end

    return false
end


-- is_block_opener: lines that open a new block body, after which the NEXT
-- line should NOT get a preceding blank line from the control-keyword rule.
-- This prevents blank lines at the very start of every if/for/function body.
local function is_block_opener(line, lang)
    -- Comments can never open a block. A comment that happens to end with
    -- "then", "do", ":", or "{" is still just a comment.
    if is_comment(line) then return false end

    local t = trimmed(line)

    if lang == "lua" then
        -- Lines whose last meaningful token opens a body:
        --   if … then  /  elseif … then  → ends with "then"
        --   for/while … do               → ends with "do"
        --   repeat                       → keyword alone
        --   else                         → keyword alone
        --   function definitions         → mirrored here so the body's first
        --                                  line sees prev_was_opener = true
        return t == "else"
            or t:match("^elseif%s") ~= nil
            or t:match("then$") ~= nil
            or t:match("%sdo$") ~= nil
            or t == "do"
            or t == "repeat"
            or t:match("^function%s") ~= nil
            or t:match("^local%s+function%s") ~= nil

    end

    if lang == "javascript" or lang == "typescript" then
        return t:match("{$") ~= nil
            or t:match("^}%s*else") ~= nil
            or t:match("^else%s*{") ~= nil
            or t:match("^}%s*catch") ~= nil
            or t:match("^}%s*finally") ~= nil

    end

    if lang == "python" then
        -- Any line ending with : opens a block body.
        return t:match(":$") ~= nil
    end

    if lang == "c" or lang == "cpp" or lang == "java" then
        return t == "{" or t:match("{$") ~= nil
            or t:match("^}%s*else") ~= nil
            or t:match("^}%s*catch") ~= nil
            or t:match("^}%s*finally") ~= nil
    end

    return false
end


-- is_control_keyword: lines that deserve a blank line before them when they
-- follow a plain statement (not a blank, not a comment, not a block opener,
-- not inside brackets). Skipped for Python - black handles Python spacing.
local function is_control_keyword(line, lang)
    if lang == "python" then return false end
    -- Comments are never control keywords.
    if is_comment(line) then return false end

    local t = trimmed(line)

    return t:match("^return[%s;]") ~= nil or t == "return"
        or t:match("^if[%s%(]") ~= nil
        or t:match("^for[%s%(]") ~= nil
        or t:match("^while[%s%(]") ~= nil
        or (lang == "lua" and t:match("^repeat%s") ~= nil)

end


-- count_net_brackets: how much this line changes bracket nesting depth.
-- Scans past string literals (so brackets inside them are never counted) with
-- a real character-by-character scanner - a previous version stripped strings
-- with a naive `"[^"]*"` / `'[^']*'` gsub, which breaks the instant a line
-- has a quote character embedded inside the OTHER quote type (e.g. a Lua
-- string literal containing `'"'`) - the regex has no notion of which quote
-- started a string, so it happily pairs up unrelated quote characters across
-- string boundaries and can strip (or fail to strip) real code along with
-- it. That's not a hypothetical: this exact file's own count_net_brackets
-- definition, a few lines below, contains lines shaped exactly like that,
-- and running this formatter on itself produced a permanently-stuck nonzero
-- bracket_depth for the rest of the file as a result.
--
-- Only ( and [ are tracked here - they mark an expression (a call, an
-- argument list, an array literal) that can wrap across several lines, and
-- while one is left open we want to suspend all blank-line insertion so a
-- wrapped argument list doesn't get split up.
--
-- { and } are CODE BLOCK delimiters (function bodies, class bodies,
-- if-blocks...), not expression brackets, and must NOT be counted here: an
-- Allman-style opening brace sits alone on its own line, so counting it
-- would push bracket_depth above zero for the rest of the block and never
-- bring it back down until the block's closing brace - permanently
-- disabling every bracket_depth == 0 gated rule (including the blank line
-- between methods this file exists to add) for everything inside.
local function count_net_brackets(line)
    local net       = 0
    local in_string = nil   -- nil, or the quote character we're inside
    local i, n      = 1, #line

    while i <= n do
        local c = line:sub(i, i)

        if in_string then
            if c == "\\" then
                i = i + 1   -- skip the escaped character, whatever it is
            elseif c == in_string then
                in_string = nil
            end
        elseif c == '"' or c == "'" then
            in_string = c
        elseif c == "(" or c == "[" then
            net = net + 1
        elseif c == ")" or c == "]" then
            net = net - 1
        end

        i = i + 1
    end

    return net
end

-- =============================================================================
-- Pass 0: em dash / en dash replacement
-- =============================================================================
-- Replaces the Unicode em dash (-, U+2014) and en dash (-, U+2013) with a
-- plain hyphen-minus (-). These characters are common in AI-generated text and
-- documentation but are not valid in most code contexts and cause encoding
-- issues in terminals and diff tools.
--
-- Replacement happens on every line INCLUDING comments and strings because
-- the dashes are almost never intentional in source code.
-- UTF-8 byte sequences:  em dash = E2 80 94,  en dash = E2 80 93.
local EM_DASH = "\xE2\x80\x94"
local EN_DASH = "\xE2\x80\x93"


local function replace_dashes(lines)
    local out = {}

    for _, line in ipairs(lines) do
        line = line:gsub(EM_DASH, "-")
        line = line:gsub(EN_DASH, "-")
        table.insert(out, line)
    end

    return out
end


-- =============================================================================
-- Import sorting
-- =============================================================================
-- Sorts import lines alphabetically within each blank-line-separated group.
-- Groups are preserved as-is - only the order within each group changes.
-- This keeps intentional groupings (stdlib / third-party / local) intact.
local function sort_imports(lines, lang)
    local out = {}
    local i   = 1

    while i <= #lines do
        if not is_import(lines[i], lang) then
            table.insert(out, lines[i])
            i = i + 1
        else
            -- Collect the full import region including internal blank lines.
            local region = {}

            while i <= #lines
                and (is_import(lines[i], lang)
                    or (is_blank(lines[i])
                        and i < #lines
                        and is_import(lines[i + 1], lang)))
            do
                table.insert(region, lines[i])
                i = i + 1
            end

            -- Split region at blank lines into independent groups.
            local groups  = {}
            local current = {}

            for _, rline in ipairs(region) do
                if is_blank(rline) then
                    if #current > 0 then
                        table.insert(groups, current)
                        current = {}
                    end
                else
                    table.insert(current, rline)
                end
            end

            if #current > 0 then
                table.insert(groups, current)
            end

            -- Sort each group independently and emit with blank separators.
            for gi, grp in ipairs(groups) do
                table.sort(grp, function(a, b)
                    return a:lower() < b:lower()
                end)

                for _, l in ipairs(grp) do
                    table.insert(out, l)
                end

                if gi < #groups then
                    table.insert(out, "")
                end
            end
        end
    end

    return out
end


-- =============================================================================
-- HTML class sorting
-- =============================================================================
-- Finds  class="…"  attributes, sorts the class names alphabetically, and
-- stacks them vertically - one class per line, indented one step under
-- whatever line the class attribute itself landed on. Uses the same fixed
-- indent-step convention as sort_html_attributes (and everything else in this
-- file) rather than aligning to the opening quote's column - column
-- alignment silently breaks the moment the content before it changes length,
-- which is exactly the kind of fragile whitespace this file exists to avoid.
local function sort_html_classes(lines)
    local out = {}

    for _, line in ipairs(lines) do
        local prefix, classes, suffix = line:match('^(.-)class="([^"]+)"(.*)')

        if classes then
            local cls_list = {}

            for cls in classes:gmatch("%S+") do
                table.insert(cls_list, cls)
            end

            table.sort(cls_list, function(a, b)
                return a:lower() < b:lower()
            end)

            if #cls_list <= 1 then
                table.insert(out, line)
            else
                local this_indent = prefix:match("^(%s*)")
                local step        = this_indent .. "    "
                table.insert(out, prefix .. 'class="' .. cls_list[1])

                for j = 2, #cls_list - 1 do
                    table.insert(out, step .. cls_list[j])
                end

                table.insert(out, step .. cls_list[#cls_list] .. '"' .. suffix)
            end
        else
            table.insert(out, line)
        end
    end

    return out
end


-- sort_html_attributes: for an opening tag with 2+ attributes sitting on a
-- single line, sort the attributes alphabetically by name and stack them one
-- per line, indented one step under the tag - e.g.
--   <h1 tag1="" tag2="" tag3="">
-- becomes
--   <h1 tag1=""
--       tag2=""
--       tag3="">
-- A tag with 0 or 1 attributes is left alone (mirrors sort_html_classes'
-- own "nothing to sort" threshold). A tag whose attributes already span
-- multiple lines is left alone too - this is a hand-rolled tokenizer, not a
-- real HTML parser, so it only handles the single-line case (the common
-- case; djlint only wraps a tag onto multiple lines when it's unusually long).
local function sort_html_attributes(lines)
    local out = {}

    for _, line in ipairs(lines) do
        local indent, after_indent = line:match("^(%s*)(.*)$")
        local tag, rest = after_indent:match("^<([%a][%w%-]*)(.*)$")
        local reflowed = false

        if tag then
            -- Scan for this tag's own closing ">", respecting quoted attribute
            -- values (which may themselves contain > or <) and bailing out if
            -- we hit an unescaped "<" first - that means this isn't a simple
            -- single-line tag and we leave it untouched.
            local n, in_quote, close_pos = #rest, nil, nil

            for i = 1, n do
                local c = rest:sub(i, i)

                if in_quote then
                    if c == in_quote then in_quote = nil end
                elseif c == '"' or c == "'" then
                    in_quote = c
                elseif c == ">" then
                    close_pos = i
                    break
                elseif c == "<" then
                    break
                end
            end

            if close_pos then
                local inner    = rest:sub(1, close_pos - 1)
                local trailing = rest:sub(close_pos + 1)
                local self_closing = inner:match("/%s*$") ~= nil

                if self_closing then
                    inner = inner:gsub("/%s*$", "")
                end

                -- Tokenize inner into individual attribute strings. Quote
                -- style is normalized to double quotes here (single -> double)
                -- UNLESS the value itself contains a literal double quote, in
                -- which case it's left exactly as authored rather than risk
                -- producing an unescaped " inside the value - HTML attribute
                -- values have no backslash-escape for quotes, so that's the
                -- one case where touching it could actually corrupt the markup.
                local attrs, j, m, ok = {}, 1, #inner, true

                while j <= m do
                    local ws_e = inner:find("[^%s]", j)

                    if not ws_e then break end

                    j = ws_e

                    local name_s, name_e = inner:find("^[%w%-:%.]+", j)

                    if not name_s then ok = false break end

                    local name = inner:sub(name_s, name_e)
                    local k    = name_e + 1
                    local eq_e = inner:match("^%s*=%s*()", k)

                    if eq_e then
                        local qchar = inner:sub(eq_e, eq_e)

                        if qchar == '"' or qchar == "'" then
                            local _, val_e = inner:find(qchar .. "[^" .. qchar .. "]*" .. qchar, eq_e)

                            if not val_e then ok = false break end

                            local value = inner:sub(eq_e + 1, val_e - 1)
                            local raw

                            if qchar == "'" and not value:find('"', 1, true) then
                                raw = name .. '="' .. value .. '"'
                            else
                                raw = inner:sub(name_s, val_e)
                            end

                            table.insert(attrs, { name = name, raw = raw })
                            j = val_e + 1
                        else
                            local _, val_e = inner:find("^%S+", eq_e)

                            if not val_e then ok = false break end

                            table.insert(attrs, { name = name, raw = inner:sub(name_s, val_e) })
                            j = val_e + 1
                        end
                    else
                        table.insert(attrs, { name = name, raw = name })
                        j = k
                    end
                end

                if ok and #attrs > 0 then
                    local closer = (self_closing and " />" or ">") .. trailing

                    if #attrs >= 2 then
                        table.sort(attrs, function(a, b)
                            return a.name:lower() < b.name:lower()
                        end)

                        local step = indent .. "    "

                        table.insert(out, indent .. "<" .. tag .. " " .. attrs[1].raw)

                        for idx = 2, #attrs do
                            table.insert(out, step .. attrs[idx].raw)
                        end

                        out[#out] = out[#out] .. closer
                    else
                        -- Only one attribute: nothing to sort or stack, but
                        -- still rebuild the line so quote normalization above
                        -- takes effect.
                        table.insert(out, indent .. "<" .. tag .. " " .. attrs[1].raw .. closer)
                    end

                    reflowed = true
                end
            end
        end

        if not reflowed then
            table.insert(out, line)
        end
    end

    return out
end

-- =============================================================================
-- Allman brace rewriters
-- =============================================================================
local INDENT = "    "


local function allman_css_rewriter(lines)
    local out   = {}
    local level = 0

    for _, line in ipairs(lines) do
        local t = trimmed(line)

        if is_comment(line) then
            table.insert(out, line)
        elseif t:match("{$") then
            local before = t:gsub("{%s*$", ""):match("^(.-)%s*$")

            if before ~= "" then
                table.insert(out, INDENT:rep(level) .. before)
            end

            table.insert(out, INDENT:rep(level) .. "{")
            level = level + 1
        elseif t:match("^}") then
            level = math.max(level - 1, 0)
            table.insert(out, INDENT:rep(level) .. "}")

            -- Only separate top-level rules with a blank line. Without the
            -- level == 0 check this fires after EVERY closing brace,
            -- including a nested rule's, inserting a spurious blank between
            -- the nested rule and its own parent's closing brace.
            if level == 0 then
                table.insert(out, "")
            end
        else
            table.insert(out, INDENT:rep(level) .. t)
        end
    end

    return out
end


local function is_js_block_brace(before)
    before = before:match("^(.-)%s*$")

    return before:match("%)$") ~= nil
        or before:match("=>$") ~= nil
        or before:match("^else$") ~= nil
        or before:match("}%s*else$") ~= nil
        or before:match("^try$") ~= nil
        or before:match("^finally$") ~= nil
        or before:match("}%s*finally$") ~= nil
        or before:match("^do$") ~= nil
        or before:match("^class%s+") ~= nil

end


local function js_allman_rewriter(lines)
    local out = {}

    for _, line in ipairs(lines) do
        if is_comment(line) then
            table.insert(out, line)
        else
            -- Strip inline comment before checking for trailing { so that
            -- a comment like  // some description {  is not split.
            local code = line:gsub("//%s*.*$", ""):match("^(.-)%s*$")

            if code:match("[^{]{$") or code == "{" then
                local ind    = line:match("^(%s*)")
                local t      = trimmed(code)
                local before = t:gsub("{%s*$", ""):match("^(.-)%s*$")

                if before == "" then
                    table.insert(out, line)
                elseif is_js_block_brace(before) then
                    table.insert(out, ind .. before)
                    table.insert(out, ind .. "{")
                else
                    table.insert(out, line)
                end
            else
                table.insert(out, line)
            end
        end
    end

    return out
end


local function lua_allman_rewriter(lines)
    local out = {}

    for _, line in ipairs(lines) do
        if is_comment(line) then
            table.insert(out, line)
        else
            -- Strip inline Lua comment before checking for trailing { so that
            -- a comment like  -- opens like {  is not split.
            local code = line:gsub("%-%-%s*.*$", ""):match("^(.-)%s*$")

            if code:match("[^{]{$") then
                local ind    = line:match("^(%s*)")
                local t      = trimmed(line)
                local before = t:gsub("{%s*$", ""):match("^(.-)%s*$")

                if before ~= "" then
                    table.insert(out, ind .. before)
                end

                table.insert(out, ind .. "{")
            else
                table.insert(out, line)
            end
        end
    end

    return out
end


-- =============================================================================
-- Universal post-processor
-- =============================================================================
local function universal_post_processor(lines, lang)
    -- ── Pass 0: replace em dash and en dash with hyphen-minus ─────────────────
    lines = replace_dashes(lines)
    -- ── Pass 1: normalise whitespace ──────────────────────────────────────────
    -- Expand tabs, strip trailing spaces, strip CR so all endings are LF.
    local cleaned = {}

    for _, line in ipairs(lines) do
        line = line:gsub("\r", "")
        line = line:gsub("\t", "    ")
        line = line:match("^(.-)%s*$")
        table.insert(cleaned, line)
    end

    lines = cleaned

    -- ── Pass 2: sort imports ──────────────────────────────────────────────────
    lines = sort_imports(lines, lang)

    -- ── Pass 3a: sort HTML tag attributes ─────────────────────────────────────
    -- Scoped to html only for now - JSX/Vue attribute syntax (expression
    -- values in {}, camelCase event props) would need its own tokenizer.
    if lang == "html" then
        lines = sort_html_attributes(lines)
    end

    -- ── Pass 3: sort HTML class attributes ───────────────────────────────────
    if lang == "html" or lang == "javascript" or lang == "typescript" then
        lines = sort_html_classes(lines)
    end

    -- ── Pass 4: blank-line spacing rules ─────────────────────────────────────
    --
    -- We rebuild the output from scratch, inserting blank lines where the rules
    -- require them. Input blank lines are DISCARDED and reconstructed.
    --
    -- State variables:
    --
    --   bracket_depth    - unclosed ( [ { count. When > 0 we are inside a call
    --                      or collection literal: suppress ALL blank insertion.
    --
    --   in_docstring     - true while inside a multi-line """ / ''' / [[ string.
    --                      All lines are emitted verbatim; no blank rules apply.
    --                      CRITICAL: docstring detection is ONLY triggered on
    --                      non-comment lines. A comment that contains """ or [[
    --                      is just a comment, never a docstring opener.
    --
    --   prev_was_blank   - last input line was blank (initialised true so the
    --                      file-start never gets a spurious leading blank).
    --
    --   prev_was_comment - last output line was a comment.
    --                      Consecutive comments are never split by blank lines.
    --
    --   prev_was_opener  - last output line opened a block (then/do/:/{ etc.).
    --                      Suppresses blank lines at the start of block bodies.
    --
    --   prev_was_decorator - last output line was a decorator (@something).
    --                        The decorator carries the blank-line budget for its
    --                        class/def; suppresses the def's own ensure_blanks.
    --
    --   same_kw_run      - consecutive lines sharing the same leading keyword.
    --                      After 4+ lines, one blank is inserted when it ends.
    --
    -- Comment look-ahead:
    --   When a standalone comment is encountered, we look ahead to find the
    --   next non-blank, non-comment, non-decorator line. If that line is a
    --   top-level def, we insert TWO blank lines BEFORE the comment so the
    --   definition visually "owns" the spacing above it.
    local out                = {}
    local bracket_depth      = 0
    local in_docstring       = false
    local docstring_delim    = nil
    local prev_was_blank     = true
    local prev_was_comment   = false
    local prev_was_opener    = false
    local prev_was_decorator = false
    local same_kw_run        = 0
    local prev_keyword       = nil

    -- Docstring delimiter constants built from char codes to avoid any
    -- confusion with Lua string quoting (these are the literal sequences
    -- triple-double-quote and triple-single-quote).
    local DTRIPLE = string.char(34, 34, 34)   -- """
    local STRIPLE = string.char(39, 39, 39)   -- '''

    -- next_code_idx: index of the first line at or after `start` that is not
    -- blank, not a comment, and not a decorator (@something). Used to look
    -- ahead and find what a comment block actually precedes.
    local function next_code_idx(arr, start)
        for j = start, #arr do
            local l = arr[j]

            if not is_blank(l)
                and not is_comment(l)
                and not trimmed(l):match("^@%w")
            then
                return j
            end
        end

        return nil
    end

    -- ensure_blanks: guarantee the output tail has exactly `n` blank lines.
    local function ensure_blanks(n)
        local have = 0

        for k = #out, math.max(1, #out - n), -1 do
            if out[k] == "" then
                have = have + 1
            else
                break
            end
        end

        for _ = 1, n - have do
            table.insert(out, "")
        end
    end

    for i, line in ipairs(lines) do

        -- ── Multi-line string passthrough ─────────────────────────────────────
        -- When inside a docstring every line (including blank lines) is emitted
        -- verbatim. We check for the closing delimiter with plain find() to
        -- avoid pattern-escape issues with """ and '''.
        if in_docstring then
            table.insert(out, line)

            if line:find(docstring_delim, 1, true) then
                in_docstring  = false
                docstring_delim = nil
            end

            goto continue
        end

        -- Detect the START of a multi-line string, but ONLY on non-comment lines.
        -- A comment containing """ or [[ is just a comment - never a docstring.
        if not is_comment(line) then
            local opener = nil
            local close  = nil

            if line:find(DTRIPLE, 1, true) then
                opener = DTRIPLE
                close  = DTRIPLE
            elseif line:find(STRIPLE, 1, true) then
                opener = STRIPLE
                close  = STRIPLE
            elseif line:find("[[", 1, true) then
                opener = "[["
                close  = "]]"
            end

            if opener then
                local s = line:find(opener, 1, true)
                local e = line:find(close, s + #opener, true)

                -- Opens and closes on the same line: single-line string, no state.
                if not e then
                    in_docstring  = true
                    docstring_delim = close
                end

                table.insert(out, line)
                prev_was_blank    = false
                prev_was_comment  = false
                prev_was_opener   = false
                prev_was_decorator = false

                goto continue
            end
        end

        -- ── Discard input blank lines - we reconstruct spacing ourselves ───────
        if is_blank(line) then
            prev_was_blank = true
            goto continue
        end

        -- ── Comment lines ─────────────────────────────────────────────────────
        -- NEVER split consecutive comment lines. This preserves section banners:
        --   -- ============
        --   -- Section      ← no blank inserted here
        --   -- ============
        --
        -- Never a blank line AFTER a comment (see the emit code below, which
        -- suppresses the standard "blank before a def" rules whenever the
        -- previous line was a comment) - a comment always hugs whatever it's
        -- describing.
        --
        -- Before a comment, two cases:
        --   - It's attached to a definition (the next real code line is a
        --     top-level def or nested method): the comment gets that def's own
        --     blank-line budget (2 or 1) instead of the def itself, so the
        --     definition visually owns the spacing.
        --   - Otherwise it's a standalone comment: preserve the author's own
        --     choice, capped at one blank line - if they didn't leave a blank,
        --     don't invent one; if they left one (or several), collapse to one.
        if is_comment(line) then
            if not prev_was_comment and bracket_depth == 0 then
                local next_code = next_code_idx(lines, i + 1)

                if next_code and is_top_level_def(lines[next_code], lang) then
                    ensure_blanks(2)
                elseif next_code and is_method_def(lines[next_code], lang) then
                    ensure_blanks(1)
                elseif prev_was_blank then
                    ensure_blanks(1)
                end
            end

            table.insert(out, line)
            prev_was_comment  = true
            prev_was_blank    = false
            prev_was_opener   = false
            prev_was_decorator = false
            prev_keyword      = nil

            same_kw_run       = 0

            goto continue
        end

        -- ── From here: non-blank, non-comment, non-docstring code ─────────────
        -- Save the pre-reset values so the decorator / def handlers can inspect
        -- what immediately preceded this line before the flags are cleared.
        local was_comment   = prev_was_comment
        local was_decorator = prev_was_decorator
        local was_opener    = prev_was_opener
        prev_was_comment    = false

        -- prev_was_decorator is reset per-branch below, not here globally.
        -- ── Decorator lines (@something) ──────────────────────────────────────
        -- Decorators carry the blank-line budget of the def/class they annotate.
        -- We fire ensure_blanks HERE, before the decorator, then set a flag so
        -- the class/def line that follows does NOT add its own blanks.
        if trimmed(line):match("^@%w") then
            if not was_decorator and not was_opener and bracket_depth == 0 and #out > 0 then
                local next_code = next_code_idx(lines, i + 1)

                if next_code and is_top_level_def(lines[next_code], lang) then
                    ensure_blanks(2)
                elseif next_code and is_method_def(lines[next_code], lang) then
                    ensure_blanks(1)
                end
            end

            table.insert(out, line)
            prev_was_blank     = false
            prev_was_opener    = false
            prev_was_decorator = true
            prev_keyword       = nil

            same_kw_run        = 0
            bracket_depth      = math.max(0, bracket_depth + count_net_brackets(line))

            goto continue
        end

        -- ── Top-level definitions ─────────────────────────────────────────────
        -- Never a blank line right after an opening brace: there's nothing
        -- above it yet to separate from, no matter what follows.
        if is_top_level_def(line, lang) and bracket_depth == 0 then
            if #out > 0 and not was_comment and not was_decorator and not was_opener then
                ensure_blanks(2)
            end

            table.insert(out, line)
            prev_was_blank     = false
            prev_was_opener    = is_block_opener(line, lang)
            prev_was_decorator = false
            prev_keyword       = nil

            same_kw_run        = 0
            bracket_depth      = math.max(0, bracket_depth + count_net_brackets(line))

            goto continue
        end

        -- ── Nested method / function definitions ──────────────────────────────
        -- Same rule: never a blank line right after an opening brace, even
        -- when the first thing inside the block is itself a method.
        if is_method_def(line, lang) and bracket_depth == 0 then
            if #out > 0 and not was_comment and not was_decorator and not was_opener then
                ensure_blanks(1)
            end

            table.insert(out, line)
            prev_was_blank     = false
            prev_was_opener    = is_block_opener(line, lang)
            prev_was_decorator = false
            prev_keyword       = nil

            same_kw_run        = 0
            bracket_depth      = math.max(0, bracket_depth + count_net_brackets(line))

            goto continue
        end

        -- ── Preserve top-level blank lines between plain assignments ───────────
        -- When the original had a blank line between two non-def, non-import
        -- lines at bracket depth 0, keep it. This preserves intentional spacing
        -- in constant / configuration blocks.
        if bracket_depth == 0
            and prev_was_blank
            and not was_comment
            and not prev_was_opener
            and not is_top_level_def(line, lang)
            and not is_method_def(line, lang)
            and not is_comment(line)
            and #out > 0

        then
            ensure_blanks(1)
        end

        -- ── Same-keyword run tracking ─────────────────────────────────────────
        local this_keyword = trimmed(line):match("^(%w+)")

        if bracket_depth == 0 then
            if prev_keyword ~= nil and this_keyword ~= prev_keyword then
                if same_kw_run >= 4 then
                    ensure_blanks(1)
                end

                same_kw_run = 1
            elseif prev_keyword ~= nil then
                same_kw_run = same_kw_run + 1
            else
                same_kw_run = 1
            end
        end

        -- ── Control-keyword blank lines ───────────────────────────────────────
        -- One blank line before return / if / for / while / repeat when the
        -- preceding output line is plain code. Skipped for Python (black handles
        -- Python spacing) and when inside brackets.
        if bracket_depth == 0
            and not prev_was_blank
            and not prev_was_opener
            and not was_decorator
            and is_control_keyword(line, lang)

        then
            local prev_out = out[#out]

            if prev_out and prev_out ~= "" and not is_comment(prev_out) then
                table.insert(out, "")
            end
        end

        -- ── Emit ──────────────────────────────────────────────────────────────
        table.insert(out, line)
        prev_was_blank     = false
        prev_was_opener    = is_block_opener(line, lang)
        prev_was_decorator = false
        prev_keyword       = this_keyword

        bracket_depth      = math.max(0, bracket_depth + count_net_brackets(line))

        ::continue::
    end

    -- ── Pass 4b: header comment - exactly one blank line after it ─────────────
    --
    -- The "header" is the first contiguous block of comment lines or a leading
    -- docstring at the top of the file (optionally preceded by a shebang).
    -- We always want exactly one blank line after the header, regardless of what
    -- follows - a require, an import, a constant, a function - doesn't matter.
    --
    -- Idempotency note: this pass walks `out` (already built by pass 4). Because
    -- pass 4 discards all input blank lines, the header will never be followed by
    -- a blank in `out` on the first run. On subsequent runs the blank is already
    -- in the INPUT and gets discarded by pass 4, so `out` is identical.
    --
    -- CRITICAL: docstring detection here, just like in pass 4, must skip comment
    -- lines. A comment that mentions """ or [[ is just a comment.
    do

        local function find_header_end(arr)
            local i = 1
            -- Skip optional shebang.
            if arr[i] and arr[i]:match("^#!") then
                i = i + 1
            end

            -- Skip any blank lines between shebang and header (edge-case safety).
            while arr[i] and is_blank(arr[i]) do
                i = i + 1
            end

            if not arr[i] then return nil end

            -- The header must start with a comment line or a docstring opener
            -- on a non-comment line.
            local first = arr[i]
            local opens_comment   = is_comment(first)
            local opens_docstring = not is_comment(first)
                and (first:find(DTRIPLE, 1, true)
                     or first:find(STRIPLE, 1, true)
                     or first:find("[[", 1, true))

            if not opens_comment and not opens_docstring then
                return nil
            end

            local last_header = nil
            local in_doc      = false
            local doc_close   = nil

            while arr[i] do
                local l = arr[i]

                if in_doc then
                    last_header = i

                    if l:find(doc_close, 1, true) then
                        in_doc    = false
                        doc_close = nil
                    end

                    i = i + 1

                elseif is_comment(l) then
                    -- Plain comment line - part of the header.
                    -- Do NOT check for docstring delimiters here: a comment that
                    -- contains """ or [[ is just a comment, not a docstring opener.
                    last_header = i
                    i = i + 1

                elseif not is_comment(l)
                    and (l:find(DTRIPLE, 1, true)
                         or l:find(STRIPLE, 1, true)
                         or l:find("[[", 1, true))
                then
                    -- Docstring opener on a non-comment line.
                    local opener = l:find(DTRIPLE, 1, true) and DTRIPLE
                               or  l:find(STRIPLE, 1, true) and STRIPLE
                               or  "[["
                    local close  = (opener == "[[") and "]]" or opener
                    local s      = l:find(opener, 1, true)
                    local e      = l:find(close, s + #opener, true)
                    last_header = i
                    if not e then
                        in_doc    = true
                        doc_close = close
                    end
                    i = i + 1
                elseif is_blank(l) then
                    break
                else
                    break
                end
            end
            return last_header
        end
        local hend = find_header_end(out)
        if hend then
            -- Remove all blank lines currently after the header.
            while out[hend + 1] and is_blank(out[hend + 1]) do
                table.remove(out, hend + 1)
            end
            -- Insert exactly one blank line - only if there is content after.
            if out[hend + 1] then
                table.insert(out, hend + 1, "")
            end
        end
    end
    -- ── Pass 4c: Python - blank line after standalone closing bracket ──────────
    -- In Python, a line that consists of only ), }, or ] (with optional
    -- whitespace but NO trailing comma) signals the end of a multi-line
    -- argument list or collection. A blank line after it improves readability
    -- by separating the call/definition from the code that follows.
    --
    -- Examples that DO get a blank line after:
    --   )         ← closing a multi-line function call
    --   }         ← closing a multi-line dict
    --   ]         ← closing a multi-line list
    --
    -- Examples that do NOT:
    --   ),        ← trailing comma means still part of an outer structure
    --   )         followed by a blank line already (collapse pass handles excess)
    if lang == "python" then
        local i = 1
        while i <= #out do
            local t = trimmed(out[i])
            -- A standalone closing bracket with no trailing comma.
            if (t == ")" or t == "}" or t == "]") then
                local next_line = out[i + 1]
                -- Only insert a blank when the next line exists and is not
                -- already blank and is not another closing bracket (to avoid
                -- blanks inside nested structures).
                if next_line
                    and not is_blank(next_line)
                    and not trimmed(next_line):match("^[%)%}%]]")
                then
                    table.insert(out, i + 1, "")
                    i = i + 2
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    -- ── Pass 4d: CSS - blank line before a declaration with an inline comment ──
    -- In CSS, inline comments (/* ... */) on declaration lines serve as
    -- section annotations. A blank line before them makes the structure clearer.
    --
    -- Rule: if a CSS declaration line contains  /* ... */  (or opens a comment
    -- with /*) AND the preceding non-blank line is also a declaration (not a
    -- { or } line, not already blank), insert one blank line before it.
    if lang == "css" then
        local i = 1
        while i <= #out do
            local line = out[i]
            local t    = trimmed(line)
            -- Detect an inline comment on this line.
            local has_inline_comment = t:match("/%*") ~= nil
                and not t:match("^/%*")   -- exclude lines that ARE a comment (start with /*)
                and not t:match("^%*")
            if has_inline_comment and i > 1 then
                local prev = out[i - 1]
                if not is_blank(prev)
                    and not trimmed(prev):match("^{")
                    and not trimmed(prev):match("^}")
                    and not is_comment(prev)
                then
                    table.insert(out, i, "")
                    i = i + 2
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    -- ── Pass 5: collapse runs of 3+ blank lines down to 2 ────────────────────
    local collapsed = {}
    local blank_run = 0
    for _, line in ipairs(out) do
        if is_blank(line) then
            blank_run = blank_run + 1
            if blank_run <= 2 then
                table.insert(collapsed, "")
            end
        else
            blank_run = 0
            table.insert(collapsed, line)
        end
    end
    -- ── Pass 6: strip leading blank lines ────────────────────────────────────
    while #collapsed > 0 and is_blank(collapsed[1]) do
        table.remove(collapsed, 1)
    end
    -- ── Pass 7: exactly one trailing newline ─────────────────────────────────
    while #collapsed > 0 and is_blank(collapsed[#collapsed]) do
        table.remove(collapsed)
    end
    table.insert(collapsed, "")
    return collapsed
end
-- =============================================================================
-- Formatter definitions
-- =============================================================================
-- ── C / C++ / Java ────────────────────────────────────────────────────────────
-- clang-format does the low-level indentation and brace placement; the
-- universal post-processor then applies the same project-wide rules used
-- for every other language (dash replacement, #include/import sorting,
-- blank-line spacing, etc.) so C, C++, and Java end up on equal footing
-- with lua/js/ts/python/css/html instead of being clang-format's raw output.
conform.formatters.clang_format_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local ft    = vim.bo[bufnr].filetype
        local fname = ctx.filename or vim.api.nvim_buf_get_name(bufnr)
        local lines = run_cmd_on_buf(bufnr,
        {
            "clang-format",
            "--style={BasedOnStyle: WebKit, BreakBeforeBraces: Allman, IndentWidth: 4}",
            "--assume-filename", fname,
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
conform.formatters.clang_format_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local ft    = vim.bo[bufnr].filetype
        local fname = ctx.filename or vim.api.nvim_buf_get_name(bufnr)
        local lines = run_cmd_on_buf(bufnr,
        {
            "clang-format",
            "--style={BasedOnStyle: WebKit, IndentWidth: 4}",
            "--assume-filename", fname,
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
-- ── CSS ───────────────────────────────────────────────────────────────────────
-- prettier does the real, from-scratch reindentation (robust to arbitrarily
-- messy input); allman_css_rewriter then relocates the "{" onto its own line
-- for the Allman variant only. Previously css_standard skipped both and left
-- whatever indentation the file already had completely untouched.
conform.formatters.css_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr,
        {
            "prettier",
            "--parser", "css",
            "--tab-width", "4",
        })
        lines = allman_css_rewriter(lines)
        return apply_to_buf(bufnr, universal_post_processor(lines, "css"))
    end,
}
conform.formatters.css_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr,
        {
            "prettier",
            "--parser", "css",
            "--tab-width", "4",
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, "css"))
    end,
}
-- ── JavaScript / TypeScript ───────────────────────────────────────────────────
-- prettier does the real, from-scratch reindentation (and line-wrapping,
-- quote/semicolon normalization, etc. - robust to arbitrarily messy input);
-- js_allman_rewriter then relocates "{" onto its own line for the Allman
-- variant only. Previously neither variant reindented anything - the brace
-- rewriter only relocated braces using whatever indentation the input line
-- already happened to have.
conform.formatters.js_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr  = ctx.buf
        if not bufnr then return {} end
        local ft     = vim.bo[bufnr].filetype
        local parser = (ft == "typescript") and "typescript" or "babel"
        local lines  = run_cmd_on_buf(bufnr,
        {
            "prettier",
            "--parser", parser,
            "--tab-width", "4",
        })
        lines = js_allman_rewriter(lines)
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
conform.formatters.js_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr  = ctx.buf
        if not bufnr then return {} end
        local ft     = vim.bo[bufnr].filetype
        local parser = (ft == "typescript") and "typescript" or "babel"
        local lines  = run_cmd_on_buf(bufnr,
        {
            "prettier",
            "--parser", parser,
            "--tab-width", "4",
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
-- ── Lua ───────────────────────────────────────────────────────────────────────
-- stylua does the real, from-scratch reindentation (robust to arbitrarily
-- messy input); lua_allman_rewriter then relocates table-literal "{" onto
-- its own line for the Allman variant only (Lua's actual control-flow blocks
-- use then/do/end, not braces - "{" only ever opens a table constructor).
-- --syntax LuaJit: Neovim's built-in Lua runtime IS LuaJIT (not stock Lua),
-- and stylua's default dialect can't parse a `goto`/`::label::` - it fails
-- outright and silently falls back to the unformatted original on any file
-- using one (this file included, until this flag was added).
conform.formatters.lua_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr,
        {
            "stylua",
            "--syntax", "LuaJit",
            "--indent-type", "Spaces",
            "--indent-width", "4",
            "-",
        })
        lines = lua_allman_rewriter(lines)
        return apply_to_buf(bufnr, universal_post_processor(lines, "lua"))
    end,
}
conform.formatters.lua_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr,
        {
            "stylua",
            "--syntax", "LuaJit",
            "--indent-type", "Spaces",
            "--indent-width", "4",
            "-",
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, "lua"))
    end,
}
-- ── Python ────────────────────────────────────────────────────────────────────
-- black handles PEP 8 spacing; the universal post-processor adds the project-
-- specific rules (standalone closing bracket blank, dash replacement, etc.).
conform.formatters.python_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr, { "black", "--quiet", "-" })
        return apply_to_buf(bufnr, universal_post_processor(lines, "python"))
    end,
}
conform.formatters.python_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr, { "black", "--quiet", "-" })
        return apply_to_buf(bufnr, universal_post_processor(lines, "python"))
    end,
}
-- ── HTML ──────────────────────────────────────────────────────────────────────
conform.formatters.html_post =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = run_cmd_on_buf(bufnr,
        {
            "djlint", "--reformat", "--quiet", "--indent", "4", "-",
        })
        return apply_to_buf(bufnr, universal_post_processor(lines, "html"))
    end,
}
-- =============================================================================
-- Formatter maps
-- =============================================================================
local allman_formatters =
{
    python     = { "python_allman" },
    c          = { "clang_format_allman" },
    cpp        = { "clang_format_allman" },
    java       = { "clang_format_allman" },
    css        = { "css_allman" },
    javascript = { "js_allman" },
    typescript = { "js_allman" },
    lua        = { "lua_allman" },
    html       = { "html_post" },
}
local standard_formatters =
{
    python     = { "python_standard" },
    c          = { "clang_format_standard" },
    cpp        = { "clang_format_standard" },
    java       = { "clang_format_standard" },
    css        = { "css_standard" },
    javascript = { "js_standard" },
    typescript = { "js_standard" },
    lua        = { "lua_standard" },
    html       = { "html_post" },
}
conform.setup({ formatters_by_ft = allman_formatters })
-- =============================================================================
-- Keybinds
-- =============================================================================
vim.keymap.set("n", "<C-f>", function()
    local ft   = vim.bo.filetype
    local fmts = allman_formatters[ft]
    if not fmts then
        vim.notify("No formatter configured for " .. ft, vim.log.levels.WARN)
        return
    end
    conform.format({ formatters = fmts, async = true })
end, { noremap = true, silent = true, desc = "Format (Allman)" })
vim.keymap.set("n", "<C-S-f>", function()
    local ft   = vim.bo.filetype
    local fmts = standard_formatters[ft]
    if not fmts then
        vim.notify("No formatter configured for " .. ft, vim.log.levels.WARN)
        return
    end
    conform.format({ formatters = fmts, async = true })
end, { noremap = true, silent = true, desc = "Format (standard / K&R)" })
