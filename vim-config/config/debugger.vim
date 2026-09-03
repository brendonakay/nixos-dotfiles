vim9script
# vimspector replaces nvim-dap, from lua/plugins/debugging.lua.
#
# This needs a Vim built with +python3, which is why ../vim/default.nix has an
# enableDebugger flag: turning it on swaps in a Vim whose closure is 1.4 GiB
# rather than 90 MiB.
#
# vimspector wants a .vimspector.json per project, where dap-python configured
# itself. The two pytest mappings from debugging.lua, <leader>Dm and <leader>DC,
# have no vimspector equivalent and are not ported.

if !isdirectory(expand('~/.vim/pack/nix/start/vimspector'))
  finish
endif

# Our own mappings below, so keep vimspector's out of the way.
g:vimspector_enable_mappings = ''

nmap <leader>Db <Plug>VimspectorToggleBreakpoint
nmap <leader>Dc <Plug>VimspectorContinue
nmap <leader>Ds <Plug>VimspectorStepOver
nmap <leader>Dj <Plug>VimspectorStepInto
nmap <leader>Dk <Plug>VimspectorStepOut
nnoremap <leader>dd <Cmd>VimspectorReset<CR>
