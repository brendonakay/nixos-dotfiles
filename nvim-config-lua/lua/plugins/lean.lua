return {
	"Julian/lean.nvim",
	event = { "BufReadPre *.lean", "BufNewFile *.lean" },

	dependencies = {
		"nvim-lua/plenary.nvim",

		-- optional dependencies:

		-- a completion engine
		--    hrsh7th/nvim-cmp or Saghen/blink.cmp are popular choices

		-- 'nvim-telescope/telescope.nvim', -- for 2 Lean-specific pickers
		-- 'andymass/vim-matchup',          -- for enhanced % motion behavior
		-- 'andrewradev/switch.vim',        -- for switch support
		-- 'tomtom/tcomment_vim',           -- for commenting
	},

	config = function()
		-- lsp = { enable = false } stops lean.setup from touching the LSP at all,
		-- which is where the deprecation warning originates. We enable leanls
		-- ourselves below; NeoVim picks up lean.nvim's bundled lsp/leanls.lua
		-- which has the correct root_dir and cmd logic.
		require('lean').setup({
			abbreviations = { builtin = true },
			mappings = true,
			lsp = { enable = false },
		})
		vim.lsp.enable('leanls')
	end,
}
