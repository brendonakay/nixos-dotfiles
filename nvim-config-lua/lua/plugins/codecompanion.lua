return {
	"olimorris/codecompanion.nvim",
	opts = {},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("codecompanion").setup({
			display = {
				diff = {
					provider = "mini_diff",
				},
			},
			opts = {
				log_level = "DEBUG",
				send_code = true,
				use_default_actions = true,
				use_default_prompts = true,
			},
			strategies = {
				chat = {
					adapter = "copilot",
				},
				inline = {
					adapter = "copilot",
				},
			},
		})
	end,
}
