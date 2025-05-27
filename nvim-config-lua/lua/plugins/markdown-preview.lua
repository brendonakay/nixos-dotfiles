-- Define the markdown-preview plugin
return {
	"iamcco/markdown-preview.nvim",
	run = "cd app && npm install", -- Ensure dependencies are installed
	config = function()
		-- Set plugin-specific settings
		vim.g.mkdp_auto_close = 1
		vim.g.mkdp_theme = "dark"
	end,
	ft = { "markdown" }, -- Load plugin for markdown filetype
}
