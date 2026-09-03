vim9script
# vim-lsp replaces nvim-lspconfig, from lua/plugins/lsp.lua.
#
# Servers are registered only when their binary is on PATH, so a machine missing
# a toolchain gets fewer servers instead of an error on startup.

# options.lua turned virtual text off, and autocommands.lua opened a float on
# CursorHold. vim-lsp does both with these settings. Vim 9 has real virtual text
# (prop_add with a text argument, new in 9.0), so inline diagnostics are
# available; they stay off to match options.lua.
g:lsp_diagnostics_virtual_text_enabled = 0
g:lsp_diagnostics_echo_cursor = 0
g:lsp_diagnostics_float_cursor = 1
g:lsp_diagnostics_float_delay = 100
g:lsp_diagnostics_signs_enabled = 1

# HLS publishes type-signature and import lenses. lsp.lua refreshed them on
# every change; vim-lsp keeps them current once lenses are enabled.
g:lsp_document_code_lens_enabled = 1
g:lsp_document_code_action_signs_enabled = 0
g:lsp_fold_enabled = 0
g:lsp_semantic_enabled = 0
g:lsp_format_sync_timeout = 500

def Register(binary: string, server: dict<any>)
  if !executable(binary)
    return
  endif
  lsp#register_server(server)
enddef

def SetupServers()
  Register('gopls', {
    name: 'gopls',
    cmd: (info) => ['gopls'],
    allowlist: ['go', 'gomod', 'gowork', 'gotmpl'],
  })

  Register('golangci-lint-langserver', {
    name: 'golangci_lint_ls',
    cmd: (info) => ['golangci-lint-langserver'],
    allowlist: ['go', 'gomod'],
    initialization_options: {command: ['golangci-lint', 'run', '--output.json.path', 'stdout']},
  })

  Register('lua-language-server', {
    name: 'lua_ls',
    cmd: (info) => ['lua-language-server'],
    allowlist: ['lua'],
  })

  Register('nil', {
    name: 'nil_ls',
    cmd: (info) => ['nil'],
    allowlist: ['nix'],
  })

  Register('pyright-langserver', {
    name: 'pyright',
    cmd: (info) => ['pyright-langserver', '--stdio'],
    allowlist: ['python'],
  })

  Register('ruff', {
    name: 'ruff',
    cmd: (info) => ['ruff', 'server'],
    allowlist: ['python'],
  })

  Register('templ', {
    name: 'templ',
    cmd: (info) => ['templ', 'lsp'],
    allowlist: ['templ'],
  })

  Register('vscode-html-language-server', {
    name: 'html',
    cmd: (info) => ['vscode-html-language-server', '--stdio'],
    allowlist: ['html', 'templ'],
    initialization_options: {provideFormatter: false},
  })

  Register('htmx-lsp', {
    name: 'htmx',
    cmd: (info) => ['htmx-lsp'],
    allowlist: ['html', 'templ'],
  })

  # The haskell block from lsp.lua, including the two lens plugins.
  Register('haskell-language-server-wrapper', {
    name: 'hls',
    cmd: (info) => ['haskell-language-server-wrapper', '--lsp'],
    allowlist: ['haskell', 'lhaskell', 'cabal'],
    workspace_config: {haskell: {
      installGhc: false,
      formattingProvider: 'ormolu',
      plugin: {
        'ghcide-type-lenses': {globalOn: true},
        importLens: {globalOn: true},
      },
    }},
  })

  Register('typos-lsp', {
    name: 'typos_lsp',
    cmd: (info) => ['typos-lsp'],
    allowlist: ['*'],
    initialization_options: {diagnosticSeverity: 'Hint'},
  })

  # typescript-tools.nvim was a Neovim-only wrapper around tsserver; plain
  # typescript-language-server covers the same filetypes. The @vue plugin it
  # loaded needs a global install, so it is left out.
  Register('typescript-language-server', {
    name: 'typescript_ls',
    cmd: (info) => ['typescript-language-server', '--stdio'],
    allowlist: ['javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'],
  })
enddef

# Keys from lsp.lua, buffer-local so they only apply where a server attached.
def SetupBuffer()
  setlocal omnifunc=lsp#complete
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> gi <plug>(lsp-implementation)
  nmap <buffer> K <plug>(lsp-hover)
  nmap <buffer> cr <plug>(lsp-rename)
  nmap <buffer> ca <plug>(lsp-code-action)
  nmap <buffer> cl <plug>(lsp-code-lens)
  nmap <buffer> [d <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]d <plug>(lsp-next-diagnostic)
enddef

augroup vimrc_lsp
  autocmd!
  autocmd User lsp_setup SetupServers()
  autocmd User lsp_buffer_enabled SetupBuffer()
augroup END
