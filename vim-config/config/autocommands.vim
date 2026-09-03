vim9script
# Autocommands, from lua/vim/autocommands.lua.
#
# The markdown block in that file moved to after/ftplugin/markdown.vim, and the
# CursorHold diagnostic float is now g:lsp_diagnostics_float_cursor in lsp.vim.

augroup vimrc_autocommands
  autocmd!
  # Filetype plugins reset 'formatoptions', so put it back after they run.
  autocmd FileType * setlocal formatoptions=jcroqlnt
augroup END
