-- Define the oil plugin
return {
	"stevearc/oil.nvim", -- Replace with the actual plugin repository if different
	config = function()
		require("oil").setup({
			skip_confirm_for_simple_edits = true,
			keymaps = {
				["<C-l>"] = false,
				["<C-r>"] = "actions.refresh",
				["y."] = "actions.copy_entry_path",
			},
		})
	end,
}
