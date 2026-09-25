-- =============================================================================
-- lua/star/runner.lua - project command runner
--
-- Project commands are defined in a `.nvim` file at the project root:
--
--     run = python3 main.py
--     dev = python3 -m flask run --debug
--     test = pytest
--
-- Keymaps:
--     <leader>rr  run
--     <leader>rd  dev
--     <leader>rt  test
--
-- If `.nvim` exists, it is always preferred.
--
-- Without `.nvim`, a small built-in fallback is available for:
--     Python, C, C++
--
-- Commands are executed inside a detached tmux window and the shell remains
-- open after the command exits so output can be inspected.
-- =============================================================================
--
-- ── Config ────────────────────────────────────────────────────────────────────

local TMUX_SHELL = "zsh"
local TMP_DIR = "/tmp/nvim-run"

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, {
        title = "Runner",
    })
end


---Run a command inside a detached tmux window.
---@param cmd string
---@param name string
local function tmux(cmd, name)
    name = name or "runner"

    local shell_cmd = string.format(
        "tmux new-window -d -n %s %s",
        vim.fn.shellescape(name),
        vim.fn.shellescape(cmd .. "; exec " .. TMUX_SHELL .. " -i")
    )

    os.execute(shell_cmd)
end


---Find a file by walking upward from `start`.
---@param start string
---@param filename string
---@return string|nil
local function find_upward(start, filename)
    local dir = vim.fn.fnamemodify(start, ":p")

    if vim.fn.isdirectory(dir) == 0 then
        dir = vim.fn.fnamemodify(dir, ":h")
    end

    while true do
        local candidate = dir .. "/" .. filename

        if vim.fn.filereadable(candidate) == 1 then
            return candidate
        end

        local parent = vim.fn.fnamemodify(dir, ":h")

        if parent == dir then
            break
        end

        dir = parent
    end

    return nil
end


---Find the project root.
---
---If `.nvim` exists somewhere above the current file, that directory is the
---project root. Otherwise fall back to the current working directory.
---@return string
local function project_root()
    local file = vim.fn.expand("%:p")

    if file ~= "" then
        local nvim_file = find_upward(file, ".nvim")

        if nvim_file then
            return vim.fn.fnamemodify(nvim_file, ":h")
        end
    end

    local cwd = vim.fn.getcwd()
    local nvim_file = find_upward(cwd, ".nvim")

    if nvim_file then
        return vim.fn.fnamemodify(nvim_file, ":h")
    end

    return cwd
end


---Read project commands from `.nvim`.
---
---Supported syntax:
---
---    run = command
---    dev = command
---    test = command
---
---Blank lines and lines beginning with `#` are ignored.
---
---@param path string
---@return table<string, string>
local function read_nvim_file(path)
    local commands = {}

    for _, line in ipairs(vim.fn.readfile(path)) do
        line = vim.trim(line)

        if line ~= "" and not line:match("^#") then
            local name, command = line:match("^([%w_-]+)%s*=%s*(.-)%s*$")

            if name and command and command ~= "" then
                commands[name] = command
            end
        end
    end

    return commands
end


---Load `.nvim` commands for the current project.
---@return table<string, string>|nil
local function load_project_commands()
    local root = project_root()
    local path = root .. "/.nvim"

    if vim.fn.filereadable(path) == 0 then
        return nil
    end

    return read_nvim_file(path)
end


---Run a named command from `.nvim`.
---@param name string
local function run_project_command(name)
    local root = project_root()
    local path = root .. "/.nvim"

    if vim.fn.filereadable(path) == 0 then
        return false
    end

    local commands = read_nvim_file(path)
    local command = commands[name]

    if not command then
        notify(".nvim has no '" .. name .. "' command.", vim.log.levels.WARN)
        return true
    end

    notify("Running " .. name .. ": " .. command)

    tmux(
        "cd " .. vim.fn.shellescape(root) .. " && " .. command,
        "nvim-" .. name
    )

    return true
end


-- ── Built-in fallback runners ─────────────────────────────────────────────────
--
-- These are deliberately limited to languages where the basic command is
-- predictable. For everything else, create a `.nvim` file.

local function fallback_run()
    local file = vim.fn.expand("%:p")
    local ext = vim.fn.expand("%:e")
    local cwd = vim.fn.getcwd()

    vim.fn.mkdir(TMP_DIR, "p")

    if ext == "py" then
        local venv = cwd .. "/venv"

        if vim.fn.isdirectory(venv) == 0 then
            notify("No venv found - creating one…", vim.log.levels.WARN)

            local result = vim.fn.system({
                "python3",
                "-m",
                "venv",
                venv,
            })

            if vim.v.shell_error ~= 0 then
                notify(
                    "Failed to create Python venv: " .. result,
                    vim.log.levels.ERROR
                )

                return
            end
        end

        notify("Running Python file")

        tmux(
            "cd "
                .. vim.fn.shellescape(cwd)
                .. " && source "
                .. vim.fn.shellescape(venv .. "/bin/activate")
                .. " && python3 "
                .. vim.fn.shellescape(file),
            "python"
        )

        return
    end

    if ext == "c" then
        local output = TMP_DIR .. "/c-run"

        notify("Compiling & running C program")

        tmux(
            "gcc "
                .. vim.fn.shellescape(file)
                .. " -o "
                .. vim.fn.shellescape(output)
                .. " && "
                .. vim.fn.shellescape(output),
            "c-run"
        )

        return
    end

    if ext == "cpp" or ext == "cc" or ext == "cxx" then
        local output = TMP_DIR .. "/cpp-run"

        notify("Compiling & running C++ program")

        tmux(
            "g++ "
                .. vim.fn.shellescape(file)
                .. " -std=c++20 -O2 -o "
                .. vim.fn.shellescape(output)
                .. " && "
                .. vim.fn.shellescape(output),
            "cpp-run"
        )

        return
    end

    notify(
        "No .nvim file and no fallback runner for ." .. ext,
        vim.log.levels.WARN
    )
end


---Run a command.
---
---`.nvim` takes priority. If it does not exist, use the fallback runner.
---@param name string
local function run(name)
    if run_project_command(name) then
        return
    end

    if name == "run" then
        fallback_run()
        return
    end

    notify(
        "No .nvim file - '" .. name .. "' has no fallback.",
        vim.log.levels.WARN
    )
end


-- ── Keymaps ───────────────────────────────────────────────────────────────────

-- <leader>rr - run
vim.keymap.set("n", "<leader>rr", function()
    run("run")
end, {
    silent = true,
    desc = "Run project",
})


-- <leader>rd - dev
vim.keymap.set("n", "<leader>rd", function()
    run("dev")
end, {
    silent = true,
    desc = "Run dev command",
})


-- <leader>rt - test
vim.keymap.set("n", "<leader>rt", function()
    run("test")
end, {
    silent = true,
    desc = "Run tests",
})

-- <leader>rc - create a .nvim project file
vim.keymap.set("n", "<leader>rc", function()
    local root = project_root()
    local path = root .. "/.nvim"

    if vim.fn.filereadable(path) == 1 then
        notify(".nvim already exists.", vim.log.levels.WARN)
        return
    end

    local template = {
        "# Neovim project commands",
        "# Commands are executed from the project root.",
        "#",
        "# Available keymaps:",
        "#   <leader>rr  -> run",
        "#   <leader>rd  -> dev",
        "#   <leader>rt  -> test",
        "",
        "run =",
        "dev =",
        "test =",
        "",
    }

    vim.fn.writefile(template, path)

    notify("Created .nvim")

    vim.cmd.edit(vim.fn.fnameescape(path))
end, {
    silent = true,
    desc = "Create project .nvim",
})

