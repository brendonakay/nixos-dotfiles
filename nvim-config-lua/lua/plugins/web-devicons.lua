-- nvim-web-devicons plugin
return {
	"nvim-tree/nvim-web-devicons",
	config = function()
		require("nvim-web-devicons").setup({
			-- Your configuration options here, if any
			default = true, -- Enable default icons
		})
	end,
}
