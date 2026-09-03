return {
	"github/copilot.vim",
	config = function()
		-- Configure the plugin settings
		vim.g.copilot_filetypes = {
			["*"] = false,
			python = true,
			haskell = false,
		}
	end,
}
