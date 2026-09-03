vim9script
# Mappings, from lua/vim/keymaps.lua. The leader keys are set in the vimrc so
# they are in place before this file runs.
#
# <Cmd> (Vim 8.2.1978) and <ScriptCmd> (Vim 9) are used throughout. Both keep
# mappings out of command-line mode, so they do not clobber the last search or
# the command history, and <ScriptCmd> can call a script-local def directly.

# NeoZoom.lua's toggle: grow the current window to fill the tab, and put the
# other windows back the way they were on the second press.
def ZoomToggle()
  if exists('t:zoom_restore')
    execute t:zoom_restore
    unlet t:zoom_restore
  else
    t:zoom_restore = winrestcmd()
    wincmd |
    wincmd _
  endif
enddef

# lazygit.nvim opened lazygit in a floating window. Vim 9 can host a terminal in
# a popup window, which is the same shape.
def LazyGit()
  if !executable('lazygit')
    echohl WarningMsg | echo 'lazygit is not installed' | echohl None
    return
  endif
  var buf = term_start('lazygit', {
    hidden: true,
    term_finish: 'close',
    curwin: false,
  })
  popup_create(buf, {
    minwidth: float2nr(&columns * 0.9),
    maxwidth: float2nr(&columns * 0.9),
    minheight: float2nr(&lines * 0.9),
    maxheight: float2nr(&lines * 0.9),
    border: [1, 1, 1, 1],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    padding: [0, 1, 0, 1],
    highlight: 'Normal',
    zindex: 200,
  })
enddef

# Copy file path to system clipboard for sharing.
def YankFilePath()
  var filepath = expand('%:.')
  setreg('+', filepath)
  echo 'Copied ' .. filepath .. ' to clipboard'
enddef

nnoremap <leader>w <C-w>

nnoremap <leader>c <Cmd>copen<CR>
nnoremap <leader>cc <Cmd>cclose<CR>
nnoremap <leader>h <Cmd>nohlsearch<CR>

# Key mappings
# :Explore opens netrw on the current file's directory, which is where oil
# opened. `-` does the same from any buffer; inside netrw its own buffer-local
# `-` takes over and goes up a directory.
nnoremap <leader>o <Cmd>Explore<CR>
nnoremap - <Cmd>Explore<CR>
nnoremap <leader>gb <ScriptCmd>g:GitBlameOpenCommitURL()<CR>
nnoremap <leader>gm <Cmd>GitMessenger<CR>
nnoremap <leader>lg <ScriptCmd>LazyGit()<CR>
nnoremap <leader>pm <Cmd>MarkdownPreview<CR>
nnoremap <leader>sg <Cmd>Rg<CR>
nnoremap <leader>sb <Cmd>Buffers<CR>
nnoremap <leader>b <Cmd>BLines<CR>
nnoremap <leader><leader> <Cmd>Files<CR>
nnoremap <leader>fr <Cmd>History<CR>
# keymaps.lua bound <leader>sc twice, to command_history and then to commands;
# the second one won, so this is :Commands.
nnoremap <leader>sc <Cmd>Commands<CR>
nnoremap <leader>d <Cmd>LspDocumentDiagnostics<CR>
nnoremap <leader>ql <Cmd>copen<CR>
nnoremap <leader>u <Cmd>UndotreeToggle<CR>
nnoremap <leader><CR> <ScriptCmd>ZoomToggle()<CR>
nnoremap <leader>yf <ScriptCmd>YankFilePath()<CR>

# which-key.nvim popped up on its own; vim-which-key needs a key of its own.
nnoremap <leader>? <Cmd>WhichKey '<Space>'<CR>
