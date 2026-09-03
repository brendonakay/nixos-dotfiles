-- Define the markdown-preview plugin
return {
	"iamcco/markdown-preview.nvim",
	build = "cd app && npx --yes yarn install",
	config = function()
		vim.g.mkdp_auto_close = 1
		vim.g.mkdp_theme = "dark"
		vim.g.mkdp_browser = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
	end,
	ft = { "markdown" }, -- Load plugin for markdown filetype
}
