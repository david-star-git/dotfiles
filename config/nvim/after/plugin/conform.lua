-- =============================================================================
-- after/plugin/conform.lua - conform.nvim formatter configuration
--
-- Two formatting modes:
--   Ctrl+F       - Allman style (opening brace on its own line)
--   Ctrl+Shift+F - Standard K&R style (opening brace on same line)
--
-- Supported languages and their formatters:
--   lua, javascript, typescript, css        - pure Lua post-processor
--   python                                  - black + post-processor
--   c, cpp, java                            - clang-format + post-processor
--   html                                    - djlint + post-processor
--
-- Universal post-processor passes (in order):
--   0.  Em dash and en dash replaced with hyphen-minus (-)
--   1.  Tabs expanded to 4 spaces, trailing whitespace trimmed, CR stripped
--   2.  Imports sorted alphabetically within each blank-line-separated group
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
--   - Anything inside unclosed brackets ( [ {
-- =============================================================================

local conform = require("conform")


-- =============================================================================
-- Low-level helpers
-- =============================================================================
-- run_cmd_on_buf: pipe the buffer through an external shell command and return
-- the result as a table of lines. Falls back to the original lines on failure.
local function run_cmd_on_buf(bufnr, cmd_parts)
    local lines   = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")

    local handle = io.popen(
        "echo " .. vim.fn.shellescape(content)
        .. " | " .. table.concat(cmd_parts, " ")
    )

    if not handle then
        return lines
    end

    local result = handle:read("*a")
    handle:close()

    local out = {}

    for s in result:gmatch("[^\r\n]+") do
        table.insert(out, s)
    end

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
            or t:match("^%w+%s*%(.*%)%s*{?$") ~= nil
    end

    if lang == "python" then
        return t:match("^def%s") ~= nil
            or t:match("^async%s+def%s") ~= nil
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

    if lang == "c" or lang == "cpp" then
        return t == "{" or t:match("{$") ~= nil
            or t:match("^}%s*else") ~= nil
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
-- Strips string literals first to avoid false positives from brackets in strings.
local function count_net_brackets(line)
    local s = line
        :gsub('"[^"]*"', "")
        :gsub("'[^']*'", "")
        :gsub("%[%[.-%]%]", "")

    local open  = select(2, s:gsub("[%(%[{]", ""))
    local close = select(2, s:gsub("[%)%]}]", ""))

    return open - close
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
-- stacks them vertically - one class per line - aligned to the opening quote.
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
                local align = string.rep(" ", #prefix + #'class="')
                table.insert(out, prefix .. 'class="' .. cls_list[1])

                for j = 2, #cls_list - 1 do
                    table.insert(out, align .. cls_list[j])
                end

                table.insert(out, align .. cls_list[#cls_list] .. '"' .. suffix)
            end
        else
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
            table.insert(out, "")
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

    -- code_since_opener: number of non-blank non-comment non-decorator lines
    -- emitted since the last block opener. Used to suppress blank lines before
    -- the first comment inside a function body even when guard clauses intervene.
    local code_since_opener = 999   -- start high so file-top comments work

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
        -- When a comment block immediately precedes a top-level definition,
        -- ensure two blank lines go BEFORE the comment (not between it and the
        -- def) so the definition visually owns the spacing.
        if is_comment(line) then
            if not prev_was_comment and bracket_depth == 0 then
                local next_code = next_code_idx(lines, i + 1)

                if i > 1 and not prev_was_blank then
                    if next_code and is_top_level_def(lines[next_code], lang) then
                        ensure_blanks(2)
                    elseif code_since_opener >= 2 then
                        -- Only add a blank before a comment when at least 2 code
                        -- lines have appeared since the last block opener. This
                        -- prevents blanks between a function header (or its guard
                        -- clauses) and the first explanatory comment in the body.
                        ensure_blanks(1)
                    end
                elseif i > 1 and prev_was_blank then
                    -- There was already a blank before this comment in the input.
                    -- Honour the top-level rule (2 blanks) or preserve the 1 blank.
                    if next_code and is_top_level_def(lines[next_code], lang) then
                        ensure_blanks(2)
                    elseif code_since_opener >= 2 then
                        ensure_blanks(1)
                    end
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
        prev_was_comment    = false

        -- prev_was_decorator is reset per-branch below, not here globally.
        -- ── Decorator lines (@something) ──────────────────────────────────────
        -- Decorators carry the blank-line budget of the def/class they annotate.
        -- We fire ensure_blanks HERE, before the decorator, then set a flag so
        -- the class/def line that follows does NOT add its own blanks.
        if trimmed(line):match("^@%w") then
            if not was_decorator and bracket_depth == 0 and #out > 0 then
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
        if is_top_level_def(line, lang) and bracket_depth == 0 then
            if #out > 0 and not was_comment and not was_decorator then
                ensure_blanks(2)
            end

            table.insert(out, line)
            prev_was_blank     = false
            prev_was_opener    = is_block_opener(line, lang)
            prev_was_decorator = false
            prev_keyword       = nil

            same_kw_run        = 0
            code_since_opener  = 0
            bracket_depth      = math.max(0, bracket_depth + count_net_brackets(line))

            goto continue
        end

        -- ── Nested method / function definitions ──────────────────────────────
        if is_method_def(line, lang) and bracket_depth == 0 then
            if #out > 0 and not was_comment and not was_decorator then
                ensure_blanks(1)
            end

            table.insert(out, line)
            prev_was_blank     = false
            prev_was_opener    = is_block_opener(line, lang)
            prev_was_decorator = false
            prev_keyword       = nil

            same_kw_run        = 0
            code_since_opener  = 0
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

        if prev_was_opener then
            code_since_opener = 0
        else
            code_since_opener = code_since_opener + 1
        end

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
conform.formatters.clang_format_allman =
{
    command = "clang-format",
    args =
    {
        "--style={BasedOnStyle: WebKit, BreakBeforeBraces: Allman, IndentWidth: 4}",
        "--stdin-filepath", "$FILENAME",
    },
    stdin = true,
}
conform.formatters.clang_format_standard =
{
    command = "clang-format",
    args =
    {
        "--style={BasedOnStyle: WebKit, IndentWidth: 4}",
        "--stdin-filepath", "$FILENAME",
    },
    stdin = true,
}
-- ── CSS ───────────────────────────────────────────────────────────────────────
conform.formatters.css_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
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
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        return apply_to_buf(bufnr, universal_post_processor(lines, "css"))
    end,
}
-- ── JavaScript / TypeScript ───────────────────────────────────────────────────
conform.formatters.js_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local ft    = vim.bo[bufnr].filetype
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        lines = js_allman_rewriter(lines)
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
conform.formatters.js_standard =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local ft    = vim.bo[bufnr].filetype
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        return apply_to_buf(bufnr, universal_post_processor(lines, ft))
    end,
}
-- ── Lua ───────────────────────────────────────────────────────────────────────
conform.formatters.lua_allman =
{
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then return {} end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
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
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
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

