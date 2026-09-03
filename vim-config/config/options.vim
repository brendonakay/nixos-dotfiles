vim9script
# Options, from lua/vim/options.lua.

# Neovim turns these on by default; Vim needs them spelled out.
filetype plugin indent on
syntax enable
set encoding=utf-8
set backspace=indent,eol,start
set hlsearch
set ruler
set wildmenu
set autoread
set display=lastline
set nrformats=bin,hex
set sessionoptions-=options
set ttimeout
set ttimeoutlen=50
set viminfo^=!

# General options
set updatetime=100                # Faster completion
set timeout                       # which-key.nvim set these two
set timeoutlen=300

# Line numbers
set relativenumber                # Relative line numbers
set number                        # Display the absolute line number of the current line

# Buffer and window behavior
set hidden                        # Keep closed buffer open in the background
set mouse=a                       # Enable mouse control
set mousemodel=extend             # Mouse right-click extends the current selection
set splitbelow                    # A new window is put below the current one
set splitright                    # A new window is put right of the current one

# File and search behavior
set noswapfile                    # Disable the swap file
set modeline                      # Tags such as 'vim:ft=sh'
set modelines=100                 # Sets the type of modelines
set undofile                      # Automatically save and restore undo history
set incsearch                     # Incremental search
set ignorecase                    # Case-insensitive search
set smartcase                     # Override 'ignorecase' if pattern contains uppercase

# Neovim keeps undo files under its own state directory; Vim writes them next to
# the edited file unless 'undodir' says otherwise.
&undodir = expand('~/.cache/vim/undo')
if !isdirectory(&undodir)
  mkdir(&undodir, 'p', 0o700)
endif

# Scrolling and cursor behavior
set scrolloff=8                   # Number of screen lines to show around the cursor
set cursorline                    # Highlight the screen line of the cursor
set cursorcolumn                  # Highlight the screen column of the cursor
set signcolumn=yes                # Always show the sign column
# lualine ran with globalstatus, which needs 'laststatus' 3. Vim 9.2 documents
# only 0, 1 and 2: it accepts 3 without complaint and then ignores it, so each
# window keeps its own status line.
set laststatus=2

# File encoding and appearance
set fileencoding=utf-8
set termguicolors                 # 24-bit RGB color in the TUI
set nospell                       # Disable spell checking
set nowrap                        # Prevent text from wrapping

# Tab options
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

# Folding
set foldlevel=300

# Vim 9.2 lines up similar lines in a diff and highlights changes within a line,
# which is the closest thing here to Neovim's diff experience.
set diffopt+=linematch:60
set diffopt+=inline:char

# From lua/vim/autocommands.lua, which set these two after the options file.
set formatoptions=jcroqlnt
set textwidth=80
