-- In-buffer markdown rendering: headings, lists, tables, code blocks
return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		heading = {
			-- Background spans the heading text rather than the whole window.
			width = "block",
			left_pad = 0,
			right_pad = 2,
		},
		code = {
			-- Background, border and language label on fenced blocks.
			style = "full",
			width = "block",
			right_pad = 2,
		},
		-- Off to avoid needing the html and latex parsers.
		html = { enabled = false },
		latex = { enabled = false },
	},
	ft = { "markdown" }, -- Load plugin for markdown filetype
}
