local hover_texts = {
    "Yes, this is faster than your IDE",
    "I know exactly what I’m doing (I don’t)",
    "Works on my machine",
    "Syntax errors are a lifestyle",
    "Because GUIs are for cowards",
    "nano users fear this",
    "Arch btw",
    "One more plugin will fix everything",
    "Pressing keys until it works",
    "This config took 6 hours",
    "If it breaks, it breaks",
    "I can quit anytime",
    "Still learning how to exit",
    "Rebinding my problems away",
    "I swear this was simpler yesterday",
    "Future me will hate this",
    "Comments are for the weak",
    "Compiles? Ship it!",
    "Will optimize later… maybe",
    "Keyboard shortcuts > social life",
    "Merge conflicts are fun, right?",
    "Error messages are suggestions",
    "Compilers always be complaining",
    "It works in theory",
    "This will break in production",
    "The comments is a lies",
    "I'll fix this tomorrow",
    "I SSH therefore I am",
}

-- Seed randomness using time + PID to avoid repeats on fast restarts
math.randomseed(os.time() + vim.fn.getpid())

-- Pick today's flavor of chaos
local neovim_hover = hover_texts[math.random(#hover_texts)]

require("presence").setup({
    auto_update = true,

    -- Hover text when someone inspects the Neovim icon on Discord
    neovim_image_text = neovim_hover,

    -- Always show Neovim, not the file icon
    main_image = "neovim",

    -- Official Presence app ID
    client_id = "793271441293967371",

    -- Keep logs quiet unless something breaks
    log_level = nil,

    -- React quickly without spamming Discord
    debounce_timeout = 1,

    -- Show project name instead of line numbers
    enable_line_number = false,

    -- No shame, no blacklists
    blacklist = {},

    -- Buttons enabled (repo detection handled automatically)
    buttons = true,

    -- Default file icons are good enough
    file_assets = {},

    -- Show how long we’ve been “working”
    show_time = true,

    -- Activity text depending on context
    editing_text = "Editing %s",
    reading_text = "Reading %s",
    workspace_text = "Working on %s",
    file_explorer_text = "Browsing %s",
    git_commit_text = "Committing changes",
    plugin_manager_text = "Managing plugins",

    -- Only used if line numbers are enabled
    line_number_text = "Line %s out of %s",
})
