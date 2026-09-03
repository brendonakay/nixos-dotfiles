vim9script
# copilot.vim, from lua/plugins/copilot.lua.
#
# copilot.vim needs Vim 9.0.0185 or newer. Run `:Copilot setup` once to
# authenticate; the plugin needs node on PATH.
#
# Filetype list straight from copilot.lua: off everywhere except Python.
g:copilot_filetypes = {
  '*': false,
  python: true,
  haskell: false,
}
