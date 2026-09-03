vim9script
# asyncomplete replaces nvim-cmp, with vim-vsnip in place of LuaSnip, from
# lua/plugins/completion.lua.
#
# Two of these 'completeopt' values need Vim 9: `popup` puts the LSP's
# documentation in a popup beside the menu, which is what cmp's <C-d> and <C-f>
# scrolled, and `fuzzy` is Vim 9.2's insert-mode fuzzy matching.
set completeopt=menuone,noinsert,noselect,popup,fuzzy
set shortmess+=c

# cmp's buffer source has no packaged equivalent: asyncomplete-buffer ships no
# license, so nixpkgs marks it unfree. 'complete' gives the same words to Vim's
# built-in <C-n> and <C-p>, and Vim 9.2 can pull from registers too.
set complete=.,w,b,u,t

g:asyncomplete_auto_popup = 1
g:asyncomplete_min_chars = 1

# Sources mirror the cmp source list: path, LSP and snippets. The LSP source
# comes from asyncomplete-lsp and the snippet source from vim-vsnip-integ, both
# of which register themselves.
def SetupSources()
  asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
    name: 'file',
    allowlist: ['*'],
    priority: 10,
    completor: function('asyncomplete#sources#file#completor'),
  }))
enddef

augroup vimrc_completion
  autocmd!
  autocmd User asyncomplete_setup SetupSources()
augroup END

# Keys from the cmp mapping table. <C-Space> arrives as <Nul> in most terminals,
# so both are mapped.
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : "\<CR>"
inoremap <expr> <C-Space> asyncomplete#force_refresh()
inoremap <expr> <Nul> asyncomplete#force_refresh()
inoremap <expr> <C-e> pumvisible() ? asyncomplete#cancel_popup() : "\<C-e>"

# cmp scrolled the documentation window with these. With completeopt+=popup the
# docs are in a popup, which Vim scrolls with the same keys.
inoremap <expr> <C-d> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
inoremap <expr> <C-f> pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-f>"

# vim-vsnip expands the snippets LSP servers return. cmp expanded them through
# LuaSnip on confirm; these keys move between the placeholders.
imap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>vsnip-jump-next' : '<Tab>'
smap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>vsnip-jump-next' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>vsnip-jump-prev' : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>vsnip-jump-prev' : '<S-Tab>'
