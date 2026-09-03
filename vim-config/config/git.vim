vim9script
# fugitive, rhubarb and git-messenger stand in for git-blame.nvim.

# git-blame.nvim's GitBlameOpenCommitURL: find the commit that last touched the
# current line, then let rhubarb turn the hash into a browser URL. Global so the
# mapping in keymaps.vim can reach it.
def g:GitBlameOpenCommitURL()
  var file = expand('%:p')
  if empty(file) || !filereadable(file)
    echohl WarningMsg | echo 'No file to blame' | echohl None
    return
  endif

  var lnum = line('.')
  var command = printf('git -C %s blame -L %d,%d --porcelain -- %s',
    shellescape(expand('%:p:h')), lnum, lnum, shellescape(file))
  var output = systemlist(command)
  if v:shell_error != 0 || empty(output)
    echohl WarningMsg | echo 'git blame failed: ' .. join(output, ' ') | echohl None
    return
  endif

  var sha = matchstr(output[0], '^\x\+')
  # An all-zero hash means the line is still uncommitted.
  if empty(sha) || sha =~# '^0\+$'
    echohl WarningMsg | echo 'Line is not committed yet' | echohl None
    return
  endif

  execute 'GBrowse' sha
enddef
