-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		teg = "0.1.0",
		-- or				 , branch = '0.1.x',
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"catppuccin/nvim",
		as = "catppuccin",
	})

	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })

	use({
		"folke/noice.nvim",
		requires = { { "MunifTanjim/nui.nvim" }, { "rcarriga/nvim-notify" } },
	})

	use({
		"nvim-lualine/lualine.nvim",
		requires = { "nvim-tree/nvim-web-devicons", opt = true },
	})

	use("nvim-tree/nvim-web-devicons")

	use({
		"nvim-tree/nvim-tree.lua",
		requires = "nvim-tree/nvim-web-devicons",
	})

	use({
		"christoomey/vim-tmux-navigator",
	})

	use({
		"vim-test/vim-test",
		requires = "preservim/vimux",
	})

	use({
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"neovim/nvim-lspconfig",
	})

	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")

	use("windwp/nvim-autopairs")

	use({
		"windwp/nvim-ts-autotag",
		requires = "nvim-treesitter/nvim-treesitter",
	})

	use("lukas-reineke/indent-blankline.nvim")

	use({
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup()
		end,
	})

    use 'andweeb/presence.nvim'

    use 'brenoprata10/nvim-highlight-colors'
end)
