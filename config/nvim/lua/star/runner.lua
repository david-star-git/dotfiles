-- =========================
-- CONFIG
-- =========================
local TMUX_SHELL = "zsh" -- change to "bash" if needed
local HTML_PORT = 8080
local TMP_DIR = "/tmp/nvim-run"

-- =========================
-- Helpers
-- =========================
notify = function(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Runner" })
end

local function tmux(cmd, name)
    name = name or "runner"
    os.execute("tmux new-window -d -n " .. vim.fn.shellescape(name) .. " '" .. cmd .. "; exec " .. TMUX_SHELL .. " -i'")
end

local function find_html_entry(cwd, file)
    -- 1. index.html in project root
    local index = cwd .. "/index.html"
    if vim.fn.filereadable(index) == 1 then
        notify("Using index.html", vim.log.levels.INFO)
        return "index.html"
    end

    -- 2. same basename as current file (style.css -> style.html)
    local base = vim.fn.fnamemodify(file, ":t:r")
    local candidate = cwd .. "/" .. base .. ".html"
    if vim.fn.filereadable(candidate) == 1 then
        notify("Using matching HTML: " .. base .. ".html", vim.log.levels.INFO)
        return base .. ".html"
    end

    -- 3. first html file in directory
    local htmls = vim.fn.glob(cwd .. "/*.html", false, true)
    if #htmls > 0 then
        local chosen = vim.fn.fnamemodify(htmls[1], ":t")
        notify("Using first HTML found: " .. chosen, vim.log.levels.WARN)
        return chosen
    end

    return nil
end

local function run_static_server(cwd, page)
    notify("Starting static server on port " .. HTML_PORT, vim.log.levels.INFO)

    tmux(
        "cd "
            .. cwd
            .. " && lsof -ti tcp:"
            .. HTML_PORT
            .. " | xargs -r kill -9"
            .. " && (sleep 0.5 && xdg-open http://localhost:"
            .. HTML_PORT
            .. "/"
            .. page
            .. ") & "
            .. "python3 -m http.server "
            .. HTML_PORT,
        "html"
    )
end

local function is_flask_project(cwd)
    if vim.fn.filereadable(cwd .. "/app.py") == 1 then
        return true
    end
    if vim.fn.filereadable(cwd .. "/wsgi.py") == 1 then
        return true
    end

    local req = cwd .. "/requirements.txt"
    if vim.fn.filereadable(req) == 1 then
        for _, line in ipairs(vim.fn.readfile(req)) do
            if line:lower():match("flask") then
                return true
            end
        end
    end

    return false
end

local function run_flask(cwd)
    local venv = cwd .. "/venv"

    if vim.fn.isdirectory(venv) == 0 then
        notify("No venv found — cannot run Flask.", vim.log.levels.ERROR)
        return
    end

    notify("Starting Flask dev server (auto-reload enabled)", vim.log.levels.INFO)

    tmux(
        "cd "
            .. cwd
            .. " && source "
            .. venv
            .. "/bin/activate"
            .. " && export FLASK_DEBUG=1"
            .. " && flask run --debug --reload --host=0.0.0.0 --port=5000",
        "flask"
    )
end

-- =========================
-- Keymap
-- =========================
vim.keymap.set("n", "<leader>r", function()
    local file = vim.fn.expand("%:p")
    local ext = vim.fn.expand("%:e")
    local cwd = vim.fn.getcwd()

    os.execute("mkdir -p " .. TMP_DIR)

    local runners = {}

    runners.py = function()
        local venv = cwd .. "/venv"
        if vim.fn.isdirectory(venv) == 0 then
            notify("No venv found — creating one…", vim.log.levels.WARN)
            os.execute("python3 -m venv " .. venv)
        end
        notify("Running Python file", vim.log.levels.INFO)
        tmux("source " .. venv .. "/bin/activate && python3 " .. file, "python")
    end

    runners.js = function()
        notify("Running JavaScript file", vim.log.levels.INFO)
        tmux("node " .. file, "node")
    end

    runners.lua = function()
        notify("Running Lua file", vim.log.levels.INFO)
        tmux("lua " .. file, "lua")
    end

    runners.c = function()
        notify("Compiling & running C program", vim.log.levels.INFO)
        tmux("gcc " .. file .. " -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out", "c-run")
    end

    runners.cpp = function()
        notify("Compiling & running C++ program", vim.log.levels.INFO)
        tmux("g++ " .. file .. " -std=c++20 -O2 -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out", "cpp-ru n")
    end

    runners.html = function()
        local page = vim.fn.fnamemodify(file, ":t")

        run_static_server(cwd, page)
    end

    runners.css = function()
        local page = find_html_entry(cwd, file)
        if not page then
            notify("No HTML file found to preview CSS.", vim.log.levels.ERROR)
            return
        end

        run_static_server(cwd, page)
    end

    runners.md = function()
        notify("Rendering Markdown preview", vim.log.levels.INFO)
        tmux(
            "pandoc " .. file .. " -o " .. TMP_DIR .. "/preview.html && xdg-open " .. TMP_DIR .. "/preview.html",
            "markdown"
        )
    end

    local run = runners[ext]
    if run then
        run()
    else
        notify("No runner configured for ." .. ext, vim.log.levels.WARN)
    end
end, { silent = true })

vim.keymap.set("n", "<leader>R", function()
    local cwd = vim.fn.getcwd()

    if is_flask_project(cwd) then
        run_flask(cwd)
    else
        notify("No Flask project detected.", vim.log.levels.WARN)
    end
end, { silent = true })
