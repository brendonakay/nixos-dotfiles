-- Define the mini-diff plugin
return {
	"echasnovski/mini.diff",
	version = "*", -- Use the latest version
	config = function()
		require("mini.diff").setup()
	end,
}
