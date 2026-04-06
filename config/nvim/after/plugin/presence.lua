-- =============================================================================
-- after/plugin/presence.lua - Discord Rich Presence
--
-- Shows the current file, project, and elapsed time on Discord.
-- The hover text (shown when someone inspects the Neovim icon) is randomly
-- selected from a list of sarcastic developer quotes on each nvim startup.
-- Commented-out entries are available — uncomment to add them to the pool.
-- =============================================================================

local hover_texts = {
    "Yes, this is faster than your IDE",
    "I know exactly what I'm doing (I don't)",
    "Because GUIs are for cowards",
    "nano users fear this",
    "Arch btw",
    "One more plugin will fix everything",
    "This config took 6 hours",
    "Compiles? Ship it!",
    "Compilers always be complaining",
    -- "Works on my machine",
    -- "Syntax errors are a lifestyle",
    -- "Pressing keys until it works",
    -- "If it breaks, it breaks",
    -- "I can quit anytime",
    -- "Still learning how to exit",
    -- "Rebinding my problems away",
    -- "I swear this was simpler yesterday",
    -- "Future me will hate this",
    -- "Comments are for the weak",
    -- "Will optimize later… maybe",
    -- "Keyboard shortcuts > social life",
    -- "Merge conflicts are fun, right?",
    -- "Error messages are suggestions",
    -- "It works in theory",
    -- "This will break in production",
    -- "The comment is a lie",
    -- "I'll fix this tomorrow",
    -- "I SSH therefore I am",
}

-- Seed with time + PID to avoid the same quote on every fast restart
math.randomseed(os.time() + vim.fn.getpid())
local neovim_hover = hover_texts[math.random(#hover_texts)]

require("presence").setup({
    auto_update = true,
    neovim_image_text = neovim_hover, -- random quote shown on Discord hover
    main_image = "neovim", -- always show the Neovim logo, not file icons
    client_id = "793271441293967371",
    log_level = nil, -- quiet unless something breaks
    debounce_timeout = 1, -- react quickly without spamming Discord
    enable_line_number = false, -- show project name, not line number
    blacklist = {},
    buttons = true, -- show repo button if detected
    file_assets = {},
    show_time = true,

    -- Activity text
    editing_text = "Editing %s",
    reading_text = "Reading %s",
    workspace_text = "Working on %s",
    file_explorer_text = "Browsing %s",
    git_commit_text = "Committing changes",
    plugin_manager_text = "Managing plugins",
    line_number_text = "Line %s out of %s",
})
