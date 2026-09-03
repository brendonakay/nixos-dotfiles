vim9script
# Plugin variables for plugins with no config file of their own. Everything here
# has to be set before the plugin loads, which is why the vimrc sources this
# ahead of packloadall.

# everforest. colorschemes.lua selected the hard background variant.
g:everforest_background = 'hard'
g:everforest_better_performance = 1
g:everforest_enable_italic = 1

# netrw is Vim's built-in file browser, standing in for oil.nvim. Only these
# settings are changed; the rest of netrw behaves as it ships.
g:netrw_banner = 0                # The banner costs five lines; `I` toggles it back
g:netrw_liststyle = 1             # Long listing: size and timestamp. `i` cycles styles
g:netrw_sort_options = 'i'        # Case-insensitive sort
g:netrw_altfile = 1               # CTRL-^ returns to the last edited file, not the browser
g:netrw_localcopydircmd = 'cp -r' # netrw defaults to plain `cp`, which cannot copy a directory

# vim-gitgutter stands in for mini.diff.
g:gitgutter_map_keys = 0
g:gitgutter_sign_priority = 9

# git-messenger shows the blame popup that git-blame.nvim put in the statusline.
g:git_messenger_include_diff = 'current'
g:git_messenger_no_default_mappings = 1

# markdown-preview, from markdown-preview.lua.
g:mkdp_auto_close = 1
g:mkdp_theme = 'dark'
g:mkdp_browser = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

# fzf.vim replaces telescope. telescope.lua's file_ignore_patterns becomes the
# fd command below, and its set_env becomes $COLORTERM.
$COLORTERM = 'truecolor'
$FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow'
  .. ' --exclude .git --exclude .mypy_cache --exclude __pycache__'
  .. ' --exclude output --exclude data --exclude "*.ipynb"'
g:fzf_layout = {window: {width: 0.9, height: 0.9}}
g:fzf_preview_window = ['right:50%', 'ctrl-/']

# vim-which-key. which-key.nvim opened on its own once 'timeoutlen' expired. Vim
# has no hook for that, so the popup is bound to <leader>? in keymaps.vim.
g:which_key_use_floating_win = 1
g:which_key_sep = '->'

# vim-markdown is the closest thing to render-markdown.nvim's in-buffer
# rendering: better syntax, concealed emphasis and link markers.
g:vim_markdown_folding_disabled = 1
g:vim_markdown_conceal_code_blocks = 0
g:vim_markdown_new_list_item_indent = 2

# undotree replaces the telescope undo picker.
g:undotree_WindowLayout = 2
g:undotree_SetFocusWhenToggle = 1
