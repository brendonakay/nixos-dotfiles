vim9script
# lightline replaces lualine. The sections follow lualine.lua: mode, branch,
# then filename and diff on the left; diagnostics, LSP server, macro recording,
# encoding, fileformat and filetype on the right.
#
# lightline calls these by name from 'component_function', so they have to be
# global rather than script-local.
#
# Plugin functions are reached through call() rather than named directly: Vim9
# resolves plain function names when it compiles the body, which would make a
# missing plugin an error instead of the empty string the guards intend.

def g:StatuslineBranch(): string
  return exists('*FugitiveHead') ? call('FugitiveHead', []) : ''
enddef

def g:StatuslineFilename(): string
  # lualine used path = 1: the directory relative to the cwd plus the file name.
  var name = expand('%:.')
  if empty(name)
    name = '[No Name]'
  endif
  var icon = ''
  if exists('*WebDevIconsGetFileTypeSymbol')
    icon = call('WebDevIconsGetFileTypeSymbol', []) .. ' '
  endif
  return icon .. name .. (&modified ? ' [+]' : '') .. (&readonly ? ' [RO]' : '')
enddef

def g:StatuslineDiff(): string
  if !exists('*GitGutterGetHunkSummary')
    return ''
  endif
  var summary = call('GitGutterGetHunkSummary', [])
  var parts = []
  for [index, prefix] in [[0, '+'], [1, '~'], [2, '-']]
    if summary[index] > 0
      add(parts, prefix .. summary[index])
    endif
  endfor
  return join(parts, ' ')
enddef

def g:StatuslineDiagnostics(): string
  if !exists('*lsp#get_buffer_diagnostics_counts')
    return ''
  endif
  var counts = lsp#get_buffer_diagnostics_counts()
  var parts = []
  for [key, label] in [['error', 'E'], ['warning', 'W'], ['information', 'I'], ['hint', 'H']]
    if get(counts, key, 0) > 0
      add(parts, label .. counts[key])
    endif
  endfor
  return join(parts, ' ')
enddef

def g:StatuslineLspServers(): string
  # lualine.lua showed the name of the LSP client attached to the buffer.
  if !exists('*lsp#get_allowed_servers')
    return ''
  endif
  return join(lsp#get_allowed_servers(), ' ')
enddef

def g:StatuslineRecording(): string
  var register = reg_recording()
  return empty(register) ? '' : 'Recording @' .. register
enddef

g:lightline = {
  colorscheme: 'everforest',
  active: {
    left: [['mode', 'paste'], ['branch'], ['filename', 'diff']],
    right: [['filetype', 'fileformat', 'fileencoding'], ['recording'], ['lsp_servers'], ['diagnostics']],
  },
  inactive: {
    left: [['filename']],
    right: [['filetype']],
  },
  component_function: {
    branch: 'StatuslineBranch',
    filename: 'StatuslineFilename',
    diff: 'StatuslineDiff',
    diagnostics: 'StatuslineDiagnostics',
    lsp_servers: 'StatuslineLspServers',
    recording: 'StatuslineRecording',
  },
}
