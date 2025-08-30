return {
	"stevearc/conform.nvim",
	config = function()
		require("conform").setup({
			format_on_save = {
				lspFallback = true,
				timeoutMs = 500,
			},
			notify_on_error = true,
			formatters_by_ft = {
				liquidsoap = { "liquidsoap-prettier" },
				html = { "prettierd" },
				css = { "prettierd" },
				javascript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				python = { "ruff_fix", "ruff_format" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				markdown = { "prettierd" },
				yaml = { "yamllint", "yamlfmt" },
				terragrunt = { "hcl" },
				bash = { "shfmt" },
				sh = { "shfmt" },
				haskell = { "hlint", "ormolu" },
			},
		})
	end,
}
