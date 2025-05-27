-- vim keymaps

-- Set global leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader>w", "<C-w>", { desc = "Window navigation" })

vim.keymap.set("n", "<leader>c", "<cmd>copen<CR>", { desc = "Open quick list" })
vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close quick list" })
vim.keymap.set("n", "<leader>h", "<cmd>noh<CR>", { desc = "Clear search highlights" })

-- Key mappings
vim.keymap.set("n", "<leader>o", ":Oil<CR>", { noremap = true, silent = true, desc = "Oil Mapping" })
vim.keymap.set(
	"n",
	"<leader>gb",
	":GitBlameOpenCommitURL<CR>",
	{ noremap = true, silent = true, desc = "Open git blame URL" }
)
vim.keymap.set(
	"n",
	"<leader>pm",
	":MarkdownPreview<CR>",
	{ noremap = true, silent = true, desc = "Open markdown preview in browser" }
)
vim.keymap.set("n", "<leader>sg", ":Telescope live_grep<CR>", { noremap = true, silent = true, desc = "Search grep" })
vim.keymap.set("n", "<leader>sb", ":Telescope buffers<CR>", { noremap = true, silent = true, desc = "Search buffers" })
vim.keymap.set(
	"n",
	"<leader>b",
	":Telescope current_buffer_fuzzy_find<CR>",
	{ noremap = true, silent = true, desc = "Search current buffer" }
)
vim.keymap.set(
	"n",
	"<leader>sc",
	":Telescope command_history<CR>",
	{ noremap = true, silent = true, desc = "Search commands" }
)
vim.keymap.set(
	"n",
	"<leader><leader>",
	":Telescope find_files<CR>",
	{ noremap = true, silent = true, desc = "Search files" }
)
vim.keymap.set("n", "<leader>fr", ":Telescope oldfiles<CR>", { noremap = true, silent = true, desc = "Search files" })
vim.keymap.set(
	"n",
	"<leader>sc",
	":Telescope commands<CR>",
	{ noremap = true, silent = true, desc = "Search commands" }
)
vim.keymap.set("n", "<leader>d", ":Telescope diagnostics<CR>", { noremap = true, silent = true, desc = "Diagnostics" })
vim.keymap.set("n", "<leader>ql", ":Telescope quickfix<CR>", { noremap = true, silent = true, desc = "Quickfix list" })
vim.keymap.set("n", "<leader>u", ":Telescope undo<CR>", { noremap = true, silent = true, desc = "Undo tree" })
