-- Call lazygit from a floating window inside NeoVim
return {
	"kdheepak/lazygit.nvim",
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	-- Draws the floating window border.
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		vim.g.lazygit_floating_window_scaling_factor = 0.9
		vim.g.lazygit_floating_window_use_plenary = 1
		-- neovim-remote is not installed, so opening files from lazygit
		-- reuses this instance instead of nesting a new one.
		vim.g.lazygit_use_neovim_remote = 0
	end,
}
