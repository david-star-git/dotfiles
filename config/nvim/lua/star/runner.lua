-- =============================================================================
-- lua/star/runner.lua - file runner
--
-- <leader>r - run the current file in a background tmux window.
-- <leader>R - start a Flask dev server for the current project.
--
-- Each filetype gets its own runner function. The runner opens a detached tmux
-- window (named by language) so the output stays visible and nvim is unblocked.
-- The window keeps a shell open after the program exits so you can read output.
--
-- Adding a new runner:
--   1. Add a function to the `runners` table keyed by file extension.
--   2. Call tmux() with the command and a window name.
-- =============================================================================

-- ── Config ────────────────────────────────────────────────────────────────────
local TMUX_SHELL = "zsh"    -- shell to keep open after the runner exits
local HTML_PORT  = 8080     -- port used by the static HTTP server for HTML/CSS
local TMP_DIR    = "/tmp/nvim-run"  -- scratch directory for compiled binaries

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- notify: wrapper around vim.notify with a "Runner" title for consistent toasts.
notify = function(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Runner" })
end

-- tmux: open a detached tmux window that runs `cmd`, then drops into the shell.
-- `name` is the window title shown in the tmux tab bar.
local function tmux(cmd, name)
    name = name or "runner"
    os.execute(
        "tmux new-window -d -n "
        .. vim.fn.shellescape(name)
        .. " '"
        .. cmd
        .. "; exec "
        .. TMUX_SHELL
        .. " -i'"
    )
end

-- find_html_entry: locate the HTML file to open for CSS/asset previews.
-- Resolution order:
--   1. index.html in the project root
--   2. <basename>.html matching the current file (style.css → style.html)
--   3. first .html file found in the directory
local function find_html_entry(cwd, file)
    local index = cwd .. "/index.html"
    if vim.fn.filereadable(index) == 1 then
        notify("Using index.html", vim.log.levels.INFO)
        return "index.html"
    end

    local base = vim.fn.fnamemodify(file, ":t:r")
    local candidate = cwd .. "/" .. base .. ".html"
    if vim.fn.filereadable(candidate) == 1 then
        notify("Using matching HTML: " .. base .. ".html", vim.log.levels.INFO)
        return base .. ".html"
    end

    local htmls = vim.fn.glob(cwd .. "/*.html", false, true)
    if #htmls > 0 then
        local chosen = vim.fn.fnamemodify(htmls[1], ":t")
        notify("Using first HTML found: " .. chosen, vim.log.levels.WARN)
        return chosen
    end

    return nil
end

-- run_static_server: kill any process on HTML_PORT, then start Python's
-- built-in HTTP server and open the browser at the given page.
local function run_static_server(cwd, page)
    notify("Starting static server on port " .. HTML_PORT, vim.log.levels.INFO)
    tmux(
        "cd " .. cwd
        .. " && lsof -ti tcp:" .. HTML_PORT .. " | xargs -r kill -9"
        .. " && (sleep 0.5 && xdg-open http://localhost:" .. HTML_PORT .. "/" .. page .. ") &"
        .. " python3 -m http.server " .. HTML_PORT,
        "html"
    )
end

-- is_flask_project: heuristic detection for Flask projects.
-- Returns true if app.py, wsgi.py, or "flask" in requirements.txt is found.
local function is_flask_project(cwd)
    if vim.fn.filereadable(cwd .. "/app.py") == 1 then return true end
    if vim.fn.filereadable(cwd .. "/wsgi.py") == 1 then return true end

    local req = cwd .. "/requirements.txt"
    if vim.fn.filereadable(req) == 1 then
        for _, line in ipairs(vim.fn.readfile(req)) do
            if line:lower():match("flask") then return true end
        end
    end

    return false
end

-- run_flask: activate the project venv and start Flask with debug/auto-reload.
local function run_flask(cwd)
    local venv = cwd .. "/venv"
    if vim.fn.isdirectory(venv) == 0 then
        notify("No venv found — cannot run Flask.", vim.log.levels.ERROR)
        return
    end
    notify("Starting Flask dev server (auto-reload enabled)", vim.log.levels.INFO)
    tmux(
        "cd " .. cwd
        .. " && source " .. venv .. "/bin/activate"
        .. " && export FLASK_DEBUG=1"
        .. " && flask run --debug --reload --host=0.0.0.0 --port=5000",
        "flask"
    )
end

-- ── Runner keybind ────────────────────────────────────────────────────────────
-- <leader>r — detect the current file's extension and call the matching runner.
vim.keymap.set("n", "<leader>r", function()
    local file = vim.fn.expand("%:p")
    local ext  = vim.fn.expand("%:e")
    local cwd  = vim.fn.getcwd()

    os.execute("mkdir -p " .. TMP_DIR)

    local runners = {}

    -- Python: create a venv if one doesn't exist, activate, then run.
    runners.py = function()
        local venv = cwd .. "/venv"
        if vim.fn.isdirectory(venv) == 0 then
            notify("No venv found — creating one…", vim.log.levels.WARN)
            os.execute("python3 -m venv " .. venv)
        end
        notify("Running Python file", vim.log.levels.INFO)
        tmux("source " .. venv .. "/bin/activate && python3 " .. file, "python")
    end

    -- JavaScript: run with Node.
    runners.js = function()
        notify("Running JavaScript file", vim.log.levels.INFO)
        tmux("node " .. file, "node")
    end

    -- Lua: run directly with the lua interpreter.
    runners.lua = function()
        notify("Running Lua file", vim.log.levels.INFO)
        tmux("lua " .. file, "lua")
    end

    -- C: compile with gcc, run the output binary.
    runners.c = function()
        notify("Compiling & running C program", vim.log.levels.INFO)
        tmux("gcc " .. file .. " -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out", "c-run")
    end

    -- C++: compile with g++ (C++20, O2 optimisation), run the output binary.
    runners.cpp = function()
        notify("Compiling & running C++ program", vim.log.levels.INFO)
        tmux("g++ " .. file .. " -std=c++20 -O2 -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out", "cpp-run")
    end

    -- HTML: start a static server and open the browser at the current file.
    runners.html = function()
        run_static_server(cwd, vim.fn.fnamemodify(file, ":t"))
    end

    -- CSS: find the associated HTML file and open a static server for it.
    runners.css = function()
        local page = find_html_entry(cwd, file)
        if not page then
            notify("No HTML file found to preview CSS.", vim.log.levels.ERROR)
            return
        end
        run_static_server(cwd, page)
    end

    -- Markdown: convert to HTML with pandoc and open in the browser.
    runners.md = function()
        notify("Rendering Markdown preview", vim.log.levels.INFO)
        tmux(
            "pandoc " .. file .. " -o " .. TMP_DIR .. "/preview.html"
            .. " && xdg-open " .. TMP_DIR .. "/preview.html",
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

-- ── Flask keybind ─────────────────────────────────────────────────────────────
-- <leader>R — detect Flask project and start the dev server.
vim.keymap.set("n", "<leader>R", function()
    local cwd = vim.fn.getcwd()
    if is_flask_project(cwd) then
        run_flask(cwd)
    else
        notify("No Flask project detected.", vim.log.levels.WARN)
    end
end, { silent = true })
