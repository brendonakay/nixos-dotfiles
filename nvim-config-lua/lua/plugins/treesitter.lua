return {
	{
		-- Tree-sitter plugin
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "python", "sql", "json", "yaml" }, -- Automatically install Python and SQL parsers
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = true,
					custom_captures = {},
				},
				-- incremental_selection = {
				-- 	enable = true,
				-- 	keymaps = {
				-- 		init_selection = false,
				-- 		node_incremental = "grn",
				-- 		node_decremental = "grm",
				-- 		scope_incremental = "grc",
				-- 	},
				-- },
				indent = {
					enable = true,
				},
				-- parser_install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "treesitter"),
				-- sync_install = false,
			})
		end,
	},
	-- Tree-sitter context plugin
	-- {
	-- 	"nvim-treesitter/nvim-treesitter-context",
	-- 	config = function()
	-- 		require("treesitter-context").setup({
	-- 			max_lines = 4,
	-- 		})
	-- 	end,
	-- },
	-- Tree-sitter refactor plugin
	-- {
	-- 	"nvim-treesitter/nvim-treesitter-refactor",
	-- 	config = function()
	-- 		require("nvim-treesitter.configs").setup({
	-- 			refactor = {
	-- 				highlight_definitions = {
	-- 					enable = true,
	-- 					clear_on_cursor_move = false,
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- },
	-- Additional plugin (hmts)
	{
		"calops/hmts.nvim",
		config = function()
			-- Configuration for hmts if needed
		end,
	},
}
