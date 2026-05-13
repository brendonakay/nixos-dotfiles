return {
	{
		"mrcjkb/haskell-tools.nvim",
		version = "^4",
		ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
		config = function()
			local ht = require("haskell-tools")
			vim.g.haskell_tools = {
				hls = {
					settings = {
						haskell = {
							installGhc = false,
							plugin = {
								hoogle = { globalOn = true },
							},
						},
					},
				},
			}

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "haskell", "lhaskell" },
				callback = function(ev)
					local bufnr = ev.buf
					local opts = { noremap = true, silent = true, buffer = bufnr }

					-- Hoogle search for word under cursor
					vim.keymap.set("n", "<leader>fh", ht.hoogle.hoogle_signature, opts)
					-- Open GHCi repl for the package
					vim.keymap.set("n", "<leader>rr", ht.repl.toggle, opts)
					-- Open GHCi repl for the current buffer
					vim.keymap.set("n", "<leader>rf", function()
						ht.repl.toggle(vim.api.nvim_buf_get_name(bufnr))
					end, opts)
					vim.keymap.set("n", "<leader>rq", ht.repl.quit, opts)
				end,
			})
		end,
	},
}
