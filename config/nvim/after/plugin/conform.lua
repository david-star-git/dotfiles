local conform = require("conform")

conform.formatters.clang_format = {
	append_args = { "-style=WebKit" },
}

conform.formatters.stylua = {
    inherit = false,
    command = "stylua",
    args = function()
        return {
            "--indent-type",
            "Spaces",
            "--indent-width",
            "4",
            "--stdin-filepath",
            "$FILENAME",
            "-",
        }
    end,
}

conform.formatters.prettier = {
    inherit = false,
    command = "prettier",
    args = function()
        return {
            "--stdin-filepath",
            "$FILENAME",
            "--tab-width",
            "4",
            "--use-tabs",
            "false",
        }
    end,
}

-- Helper to indent
local function indent(level)
    return string.rep("    ", level)
end

-- CSS Allman formatter
conform.formatters.allman_css = {
    inherit = false,
    format = function(_, ctx)
        local buf = ctx.buf or 0
        -- Always fetch current lines
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local out = {}
        local level = 0

        for _, line in ipairs(lines) do
            local trimmed = line:match("^%s*(.-)%s*$")

            -- Opening brace
            if trimmed:match("{$") then
                local before = trimmed:gsub("{%s*$", "")
                if before ~= "" then
                    table.insert(out, indent(level) .. before)
                end
                table.insert(out, indent(level) .. "{")
                level = level + 1

            -- Closing brace
            elseif trimmed:match("^}") then
                level = math.max(level - 1, 0)
                table.insert(out, indent(level) .. "}")
            else
                table.insert(out, indent(level) .. trimmed)
            end
        end

        -- Replace buffer content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)

        return out
    end,
}

local INDENT = "    "

local function format_allman_js(ctx)
    local buf = ctx.buf or 0
    local lines = ctx.lines or vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local out = {}
    local level = 0

    local function append(line)
        table.insert(out, string.rep(INDENT, level) .. line)
    end

    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")

        -- Split single-line blocks: "function() { stuff }"
        if trimmed:match("{.-}") then
            -- Capture before {
            local before = trimmed:match("^(.-){")
            local inside = trimmed:match("{(.-)}") or ""
            if before and before:match("%S") then
                append(before)
            end
            append("{")
            level = level + 1
            for stmt in inside:gmatch("[^;]+;?") do
                local s = stmt:match("^%s*(.-)%s*$")
                if s ~= "" then
                    append(s)
                end
            end
            level = level - 1
            append("}")
        -- Opening brace at end
        elseif trimmed:match("{$") then
            local before = trimmed:gsub("{%s*$", "")
            if before ~= "" then
                append(before)
            end
            append("{")
            level = level + 1
        -- Closing brace at start
        elseif trimmed:match("^}") then
            level = math.max(level - 1, 0)
            append("}")
        -- Else if / else with opening brace: "} else {"
        elseif trimmed:match("^}%s*else") and trimmed:match("{%s*$") then
            level = math.max(level - 1, 0)
            local before = trimmed:gsub("{%s*$", "")
            append(before)
            append("{")
            level = level + 1
        else
            append(trimmed)
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
    return out
end

-- Register JS/TS/JSX/TSX Allman formatter
conform.formatters.allman_js = {
    inherit = false,
    format = format_allman_js,
}

conform.setup({
    formatters_by_ft = {
        python = { "black" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        java = { "clang_format" },
        html = { "prettier" },
        css = { "allman_css" },
        scss = { "allman_css" },
        less = { "allman_css" },
        javascript = { "allman_js" },
        typescript = { "allman_js" },
        javascriptreact = { "allman_js" },
        typescriptreact = { "allman_js" },
        lua = { "stylua" },
    },
})

vim.keymap.set("n", "<C-f>", function()
    conform.format({ async = true })
end, { noremap = true, silent = true })
