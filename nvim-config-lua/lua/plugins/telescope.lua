return {
	"nvim-telescope/telescope.nvim",
	config = function()
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = {
					"^.git/",
					"^.mypy_cache/",
					"^__pycache__/",
					"^output/",
					"^data/",
					"%.ipynb",
				},
				set_env = { COLORTERM = "truecolor" },
			},
		})
	end,
}
