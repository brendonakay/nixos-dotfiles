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
			-- adapters = {
			--      copilot = function()
			--        return require("codecompanion.adapters").extend("copilot", {
			--          schema = {
			--            model = {
			--              default = "claude-3.7-sonnet",
			--            },
			--          },
			--        })
			--      end,
			--    },
			adapters = {
				copilot = "copilot",
			},
			opts = {
				log_level = "DEBUG",
				send_code = true,
				use_default_actions = true,
				use_default_prompts = true,
			},
			strategies = {
				agent = {
					adapter = "copilot",
				},
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
