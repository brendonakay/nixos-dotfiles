-- Vertically center document when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
	command = "norm zz",
})

-- Enable spellcheck for markdown filetypes
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "*.markdown", "*.md" },
	command = "setlocal spell spelllang=en",
})

-- Set colorcolumn and textwidth for markdown files on buffer enter
vim.api.nvim_create_autocmd("BufWinEnter", {
	pattern = { "*.markdown", "*.md" },
	callback = function()
		vim.opt.colorcolumn = "80"
		vim.opt.textwidth = 80
	end,
})

-- Reset colorcolumn and textwidth for markdown files on buffer leave
vim.api.nvim_create_autocmd("BufWinLeave", {
	pattern = { "*.markdown", "*.md" },
	callback = function()
		vim.opt.colorcolumn = "120"
		vim.opt.textwidth = 120
	end,
})

-- Show diagnostics float on cursor hold
vim.api.nvim_create_autocmd("CursorHold", {
	pattern = "*",
	callback = function()
		for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
			if vim.api.nvim_win_get_config(winid).zindex then
				return
			end
		end
		vim.diagnostic.open_float(0, {
			scope = "line",
			focusable = false,
			close_events = {
				"CursorMoved",
				"CursorMovedI",
				"BufHidden",
				"InsertCharPre",
				"WinLeave",
			},
		})
	end,
})
