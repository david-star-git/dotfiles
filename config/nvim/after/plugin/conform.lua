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
            "--tab-width",
            "4",
            "--stdin-filepath",
            "$FILENAME",
        }
    end,
}

local INDENT = "    " -- 4 spaces

-- Format Allman style + proper indent + space after closing braces
local function allman_style(lines)
    local out = {}
    local level = 0

    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")

        -- Opening brace at end of line
        if trimmed:match("{$") then
            local before = trimmed:gsub("{%s*$", "")
            if before ~= "" then
                table.insert(out, INDENT:rep(level) .. before)
            end
            table.insert(out, INDENT:rep(level) .. "{")
            level = level + 1

        -- Closing brace at start
        elseif trimmed:match("^}") then
            level = math.max(level - 1, 0)
            table.insert(out, INDENT:rep(level) .. "}")
            table.insert(out, "") -- blank line after closing brace

        -- Normal content
        else
            table.insert(out, INDENT:rep(level) .. trimmed)
        end
    end

    return out
end

conform.formatters.prettier_allman_css = {
    inherit = false,
    format = function(_, ctx)
        local bufnr = ctx.buf
        if not bufnr then
            return {}
        end

        local lines = ctx.lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local content = table.concat(lines, "\n")

        -- Run Prettier
        local prettier_cmd = {
            "prettier",
            "--tab-width",
            "2",
            "--stdin-filepath",
            vim.api.nvim_buf_get_name(bufnr),
        }

        local handle = io.popen("echo " .. vim.fn.shellescape(content) .. " | " .. table.concat(prettier_cmd, " "))
        if not handle then
            return lines
        end
        local formatted = handle:read("*a")
        handle:close()

        -- Split into lines
        local out = {}
        for s in formatted:gmatch("[^\r\n]+") do
            table.insert(out, s)
        end

        -- Apply Allman formatting
        out = allman_style(out)

        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
        return out
    end,
}

conform.setup({
    formatters_by_ft = {
        python = { "black" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        java = { "clang_format" },
        html = { "djlint" },
        css = { "prettier_allman_css" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        lua = { "stylua" },
    },
})

vim.keymap.set("n", "<C-f>", function()
    conform.format({ async = true })
end, { noremap = true, silent = true })
