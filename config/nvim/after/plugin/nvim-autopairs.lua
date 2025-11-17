require("nvim-autopairs").setup({
  check_ts = true,                -- use treesitter for smarter pairing
  enable_check_bracket_line = true,
  map_cr = true,                  -- auto insert brackets on Enter
  map_bs = true,                  -- auto delete pairs
})

local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done()
)
