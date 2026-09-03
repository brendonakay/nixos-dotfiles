vim9script
# todo-comments.nvim highlighted keywords inside comments and could list them in
# the quickfix window. Syntax matches and :vimgrep cover the same ground.

const KEYWORDS = ['TODO', 'FIXME', 'HACK', 'BUG', 'WARN', 'WARNING', 'PERF', 'NOTE', 'TEST']

def HighlightTodo()
  for keyword in KEYWORDS
    execute printf('syntax match vimrcTodo%s /\<%s\ze:\?/ containedin=.*Comment,.*String',
      keyword, keyword)
  endfor
enddef

highlight default link vimrcTodoTODO Todo
highlight default link vimrcTodoFIXME Error
highlight default link vimrcTodoHACK Error
highlight default link vimrcTodoBUG Error
highlight default link vimrcTodoWARN WarningMsg
highlight default link vimrcTodoWARNING WarningMsg
highlight default link vimrcTodoPERF Todo
highlight default link vimrcTodoNOTE Todo
highlight default link vimrcTodoTEST Todo

# :Todo fills the quickfix list with every keyword under the current directory.
def TodoQuickfix()
  execute 'vimgrep /\<\(' .. join(KEYWORDS, '\|') .. '\)\ze:\?/j **/*'
  copen
enddef
command! -nargs=0 Todo TodoQuickfix()

augroup vimrc_todo
  autocmd!
  autocmd Syntax * HighlightTodo()
augroup END
