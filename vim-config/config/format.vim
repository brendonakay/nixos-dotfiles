vim9script
# ALE replaces conform.nvim, from lua/plugins/conform.lua.
#
# Only the fix-on-save half of ALE is used: vim-lsp owns diagnostics, so ALE's
# own LSP client and its linters stay off.
g:ale_disable_lsp = 1
g:ale_linters_explicit = 1
g:ale_linters = {}
g:ale_fix_on_save = 1
g:ale_echo_msg_format = '[%linter%] %s'

# formatters_by_ft from conform.lua.
const FIXERS_BY_FILETYPE = {
  html: ['prettier'],
  css: ['prettier'],
  javascript: ['prettier'],
  javascriptreact: ['prettier'],
  typescript: ['prettier'],
  typescriptreact: ['prettier'],
  markdown: ['prettier'],
  python: ['ruff', 'ruff_format'],
  lua: ['stylua'],
  nix: ['nixfmt'],
  yaml: ['yamlfmt'],
  sh: ['shfmt'],
  bash: ['shfmt'],
  haskell: ['hlint', 'ormolu'],
}

# ALE fixer name -> the binary it shells out to, so a fixer with no binary
# installed is dropped instead of failing the save.
const FIXER_BINARIES = {
  prettier: 'prettier',
  ruff: 'ruff',
  ruff_format: 'ruff',
  stylua: 'stylua',
  nixfmt: 'nixfmt',
  yamlfmt: 'yamlfmt',
  shfmt: 'shfmt',
  hlint: 'hlint',
  ormolu: 'ormolu',
}

var fixers: dict<list<string>> = {}
for [filetype, names] in items(FIXERS_BY_FILETYPE)
  var available = filter(copy(names), (_, name) => executable(get(FIXER_BINARIES, name, name)))
  if !empty(available)
    fixers[filetype] = available
  endif
endfor
g:ale_fixers = fixers

# conform's lspFallback: filetypes with no fixer above are formatted by their
# language server instead. Only a server that advertises document formatting
# counts, so buffers served by something like typos-lsp are left alone.
def FormatWithLsp()
  if has_key(g:ale_fixers, &filetype)
    return
  endif
  if !exists('*lsp#get_allowed_servers')
    return
  endif
  for server in lsp#get_allowed_servers()
    if lsp#capabilities#has_document_formatting_provider(server)
      # Run through execute() so the command is resolved when this runs rather
      # than when Vim9 compiles the function, which happens before vim-lsp has
      # defined it.
      execute 'LspDocumentFormatSync'
      return
    endif
  endfor
enddef

augroup vimrc_format
  autocmd!
  autocmd BufWritePre * FormatWithLsp()
augroup END
