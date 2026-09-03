return {
	{
		-- Tree-sitter plugin
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()
			require("nvim-treesitter").install({
				"python",
				"sql",
				"json",
				"yaml",
				"javascript",
				"typescript",
				"tsx",
				"go",
				"nix",
				"toml",
				"haskell",
				"markdown",
				"markdown_inline",
			})
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
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
}
