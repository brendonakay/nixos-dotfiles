return {
	-- Enable luasnip
	{
		"L3MON4D3/LuaSnip",
		config = function()
			require("luasnip").setup()
		end,
	},
	-- Enable cmp plugins
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "s" }),
					["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "s" }),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				},
				sources = {
					{ name = "path" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								return vim.api.nvim_list_bufs()
							end,
						},
					},
					{ name = "neorg" },
				},
			})
		end,
	},
	-- Additional cmp plugins
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-nvim-lsp-document-symbol" },
	{ "hrsh7th/cmp-nvim-lsp-signature-help" },
	{ "uga-rosa/cmp-dictionary" },
	{ "hrsh7th/cmp-omni" },
	{ "rcarriga/cmp-dap" },
	-- Lspkind for icons
	{
		"onsails/lspkind-nvim",
		config = function()
			require("lspkind").init({
				mode = "symbol_text",
				preset = "default",
				symbol_map = {
					Text = "[LSP]",
					Method = "[api]",
					Function = "[path]",
					Constructor = "[snip]",
					Field = "[buffer]",
					Variable = "[neorg]",
				},
			})
		end,
	},
}
