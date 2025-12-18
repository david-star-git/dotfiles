-- =========================
-- CONFIG
-- =========================
local TMUX_SHELL = "zsh" -- change to "bash" if needed
local HTML_PORT = 8080
local TMP_DIR = "/tmp/nvim-run"

-- =========================
-- Helpers
-- =========================
local function tmux(cmd)
    os.execute("tmux new-window '" .. cmd .. "; exec " .. TMUX_SHELL .. " -i'")
end

local function find_html_entry(cwd, file)
    -- 1. index.html in project root
    local index = cwd .. "/index.html"
    if vim.fn.filereadable(index) == 1 then
        return "index.html"
    end

    -- 2. same basename as current file (style.css -> style.html)
    local base = vim.fn.fnamemodify(file, ":t:r")
    local candidate = cwd .. "/" .. base .. ".html"
    if vim.fn.filereadable(candidate) == 1 then
        return base .. ".html"
    end

    -- 3. first html file in directory
    local htmls = vim.fn.glob(cwd .. "/*.html", false, true)
    if #htmls > 0 then
        return vim.fn.fnamemodify(htmls[1], ":t")
    end

    return nil
end

local function kill_port(port)
    -- Find PIDs listening on the port and kill them
    os.execute("lsof -ti tcp:" .. port .. " | xargs -r kill -9 2>/dev/null")
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
            print("No venv found — creating one...")
            os.execute("python3 -m venv " .. venv)
        end
        tmux("source " .. venv .. "/bin/activate && python3 " .. file)
    end

    runners.js = function()
        tmux("node " .. file)
    end

    runners.lua = function()
        tmux("lua " .. file)
    end

    runners.c = function()
        tmux("gcc " .. file .. " -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out")
    end

    runners.cpp = function()
        tmux("g++ " .. file .. " -std=c++20 -O2 -o " .. TMP_DIR .. "/a.out && " .. TMP_DIR .. "/a.out")
    end

    runners.html = function()
        local page = vim.fn.fnamemodify(file, ":t")

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
                .. HTML_PORT
        )
    end

    runners.css = function()
        local page = find_html_entry(cwd, file)
        if not page then
            print("No HTML file found to preview CSS.")
            return
        end

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
                .. HTML_PORT
        )
    end

    runners.md = function()
        tmux("pandoc " .. file .. " -o " .. TMP_DIR .. "/preview.html && xdg-open " .. TMP_DIR .. "/preview.html")
    end

    local run = runners[ext]
    if run then
        run()
    else
        print("No runner configured for ." .. ext)
    end
end, { silent = true })
