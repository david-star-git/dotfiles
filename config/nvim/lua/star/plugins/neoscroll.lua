-- =============================================================================
-- lua/star/plugins/neoscroll.lua - smooth scrolling
--
-- New addition. Animates <C-d>/<C-u>/<C-f>/<C-b> and friends instead of
-- jumping instantly, for the trackpad-momentum feel macOS apps have.
-- (Paired with the built-in `smoothscroll` option set in lua/star/init.lua,
-- which smooths scrolling over wrapped lines — a different, complementary
-- thing this plugin doesn't cover.)
-- =============================================================================

return {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
        easing = "quadratic",
    },
}
