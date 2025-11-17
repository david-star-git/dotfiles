-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
    'nvim-telescope/telescope.nvim', teg = '0.1.0',
    -- or				 , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use { 
    'catppuccin/nvim', 
    as = 'catppuccin'
  }

  use (
    'nvim-treesitter/nvim-treesitter',
    {run = ':TSUpdate'}
  )

  use('mbbill/undotree')
  use('tpope/vim-fugitive')

  use {
    'folke/noice.nvim',
    requires = { {'MunifTanjim/nui.nvim'}, {'rcarriga/nvim-notify'} }
  }

  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }

  use('nvim-tree/nvim-web-devicons')

  use {
    'nvim-tree/nvim-tree.lua',
    requires = 'nvim-tree/nvim-web-devicons',
  }
  use {
    'christoomey/vim-tmux-navigator'
  }
end)
