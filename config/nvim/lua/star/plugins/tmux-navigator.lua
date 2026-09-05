-- =============================================================================
-- lua/star/plugins/tmux-navigator.lua - seamless nvim/tmux pane navigation
--
-- Provides <C-h/j/k/l> to move between nvim splits AND tmux panes with the
-- same keys, in either direction — tmux.conf detects "is_vim" and forwards
-- the same keys through. This plugin's own default binds are <C-hjkl>, which
-- is why tmux.conf's Alt+jklö bindings send C-h/j/k/l rather than your
-- remapped movement keys: they're talking to this plugin, not to your jklö
-- remap.
--
-- The direct <M-jklö> window-nav mappings (for when you're in nvim without
-- tmux around) live in remap.lua.
-- =============================================================================

return {
    "christoomey/vim-tmux-navigator",
    lazy = false,
}
