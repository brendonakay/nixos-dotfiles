-- Disable useless providers
vim.g.loaded_ruby_provider = 0 -- Ruby
vim.g.loaded_perl_provider = 0 -- Perl
vim.g.loaded_python_provider = 0 -- Python 2

-- Diagnostics settings
vim.diagnostic.config({
	-- virtual_lines = {
	-- 	only_current_line = true,
	-- },
	virtual_text = false,
})

-- Clipboard settings (commented out as in the original Nix config)
-- vim.opt.clipboard = "unnamedplus"
-- -- Enable Wayland clipboard provider
-- vim.g.clipboard = {
--   name = "wl-copy",
--   copy = { ["+"] = "wl-copy", ["*"] = "wl-copy" },
--   paste = { ["+"] = "wl-paste", ["*"] = "wl-paste" },
--   cache_enabled = true,
-- }

-- General options
vim.opt.updatetime = 100 -- Faster completion

-- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.number = true -- Display the absolute line number of the current line

-- Buffer and window behavior
vim.opt.hidden = true -- Keep closed buffer open in the background
vim.opt.mouse = "a" -- Enable mouse control
vim.opt.mousemodel = "extend" -- Mouse right-click extends the current selection
vim.opt.splitbelow = true -- A new window is put below the current one
vim.opt.splitright = true -- A new window is put right of the current one

-- File and search behavior
vim.opt.swapfile = false -- Disable the swap file
vim.opt.modeline = true -- Tags such as 'vim:ft=sh'
vim.opt.modelines = 100 -- Sets the type of modelines
vim.opt.undofile = true -- Automatically save and restore undo history
vim.opt.incsearch = true -- Incremental search: show match for partly typed search command
vim.opt.inccommand = "split" -- Search and replace: preview changes in quickfix list
vim.opt.ignorecase = true -- Case-insensitive search
vim.opt.smartcase = true -- Override 'ignorecase' if search pattern contains uppercase

-- Scrolling and cursor behavior
vim.opt.scrolloff = 8 -- Number of screen lines to show around the cursor
vim.opt.cursorline = true -- Highlight the screen line of the cursor
vim.opt.cursorcolumn = true -- Highlight the screen column of the cursor
vim.opt.signcolumn = "yes" -- Always show the sign column
vim.opt.laststatus = 3 -- Global status line

-- File encoding and appearance
vim.opt.fileencoding = "utf-8" -- File-content encoding for the current buffer
vim.opt.termguicolors = true -- Enables 24-bit RGB color in the TUI
vim.opt.spell = false -- Disable spell checking
vim.opt.wrap = false -- Prevent text from wrapping

-- Tab options
vim.opt.tabstop = 4 -- Number of spaces a <Tab> in the text stands for
vim.opt.shiftwidth = 4 -- Number of spaces used for each step of (auto)indent
vim.opt.expandtab = true -- Expand <Tab> to spaces in Insert mode
vim.opt.autoindent = true -- Enable auto-indenting

-- Text width
vim.opt.textwidth = 0 -- Disable automatic line wrapping

-- Folding
vim.opt.foldlevel = 300 -- Folds with a level higher than this number will be closed
