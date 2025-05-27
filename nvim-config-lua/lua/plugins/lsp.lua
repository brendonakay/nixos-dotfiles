-- LSP configuration
return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")

			-- Key mappings
			local keymaps = {
				n = {
					["[d"] = vim.diagnostic.goto_prev,
					["]d"] = vim.diagnostic.goto_next,
					gd = vim.lsp.buf.definition,
					gr = vim.lsp.buf.references,
					gt = vim.lsp.buf.type_definition,
					gi = vim.lsp.buf.implementation,
					K = vim.lsp.buf.hover,
					cr = vim.lsp.buf.rename,
				},
			}

			-- Apply key mappings
			for mode, mappings in pairs(keymaps) do
				for key, func in pairs(mappings) do
					vim.api.nvim_set_keymap(mode, key, "", { noremap = true, silent = true, callback = func })
				end
			end

			-- LSP servers setup
			local servers = {
				"gopls",
				"golangci_lint_ls",
				"lua_ls",
				"nil_ls",
				"pyright",
				"pylsp",
				"templ",
				"html",
				"htmx",
				"hls",
				"tailwindcss",
				"typos_lsp",
			}

			for _, server in ipairs(servers) do
				lspconfig[server].setup({})
			end

			-- Specific server configurations
			lspconfig.hls.setup({
				settings = {
					haskell = {
						installGhc = false,
					},
				},
			})

			lspconfig.typos_lsp.setup({
				init_options = {
					diagnosticSeverity = "Hint",
				},
			})
		end,
	},
	-- Fidget plugin
	{
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup({})
		end,
	},
}
