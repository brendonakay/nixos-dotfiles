" Markdown buffers, from the autocommands in lua/vim/autocommands.lua. These are
" buffer-local, so Vim applies and drops them as you move between windows,
" without the BufWinEnter and BufWinLeave pair the Lua config used.
"
" Left in legacy Vimscript: ftplugins are sourced for every markdown buffer, and
" a plain :setlocal list needs nothing Vim9 script offers.
setlocal spell spelllang=en
setlocal textwidth=80
setlocal colorcolumn=80

" vim-markdown conceals emphasis and link markers, the nearest thing to
" render-markdown.nvim's in-buffer rendering.
setlocal conceallevel=2
