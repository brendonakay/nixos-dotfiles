# Vim config

Vimscript port of the Neovim Lua config in `../nvim-config-lua`, for Vim 9.
`../vim/default.nix` is the Home Manager module that installs it.

This is the `vim` on your PATH. The module puts Vim itself in `home.packages`,
and `/etc/profiles/per-user/bkay/bin` comes before `/run/current-system/sw/bin`,
so it wins over the `pkgs.vim` in `environment.systemPackages`.

## Layout

Vim's own directory layout, so there is no path setup and no wrapper: Vim finds
`~/.vim/vimrc` by itself, `~/.vim` is already first on `'runtimepath'`,
`~/.vim/after` is already last, and `~/.vim/pack/nix/start` loads on startup.

The module links `vimrc`, `config/` and `after/` individually rather than
linking `~/.vim` wholesale, because home-manager owns `~/.vim/pack` and cannot
manage entries inside a directory that is itself an out-of-store symlink. All
three links point straight at this repo, so edits take effect on the next start
with no rebuild.

`vimrc` is legacy Vimscript on purpose; everything in `config/` is Vim9 script.
A Vim9 vimrc makes Vim apply Vim9 line-continuation rules to the legacy plugin
scripts loaded after it, so any plugin that continues a list or dictionary with a
leading backslash fails with `E10` and `E697`. ALE and markdown-preview both do.
Keeping the vimrc legacy loads plugins correctly, and each file under `config/`
is its own script, so they are still Vim9 script.

| Path | From |
| --- | --- |
| `vimrc` | `init.lua` |
| `config/options.vim` | `lua/vim/options.lua` |
| `config/keymaps.vim` | `lua/vim/keymaps.lua` |
| `config/autocommands.vim` | `lua/vim/autocommands.lua` |
| `config/plugins.vim` | plugin variables with no file of their own, and netrw |
| `config/lsp.vim` | `lua/plugins/lsp.lua` |
| `config/completion.vim` | `lua/plugins/completion.lua` |
| `config/format.vim` | `lua/plugins/conform.lua` |
| `config/statusline.vim` | `lua/plugins/lualine.lua` |
| `config/copilot.vim` | `lua/plugins/copilot.lua` |
| `config/git.vim` | `lua/plugins/gitblame.lua` |
| `config/todo.vim` | `lua/plugins/todo-comments.lua` |
| `config/debugger.vim` | `lua/plugins/debugging.lua` |
| `config/darkmode.vim` | `lua/plugins/auto-dark-mode.lua` |
| `after/ftplugin/markdown.vim` | the markdown autocommands |

## Plugins

| Neovim | Vim |
| --- | --- |
| everforest, papercolor-theme | same plugins; both support Vim |
| lualine.nvim | lightline.vim |
| telescope.nvim | fzf.vim |
| oil.nvim | netrw, which Vim ships |
| Comment.nvim | vim-commentary |
| nvim-surround | vim-surround |
| vim-sleuth | same plugin |
| git-blame.nvim | vim-fugitive, vim-rhubarb, git-messenger.vim |
| mini.diff | vim-gitgutter |
| which-key.nvim | vim-which-key |
| nvim-lspconfig, fidget.nvim | vim-lsp |
| nvim-cmp, LuaSnip | asyncomplete.vim, vim-vsnip |
| conform.nvim | ALE, fixers only |
| copilot.vim | same plugin; needs Vim 9.0.0185 or newer |
| nvim-treesitter | Vim's own syntax highlighting |
| todo-comments.nvim | `config/todo.vim` |
| NeoZoom.lua | `ZoomToggle()` in `config/keymaps.vim` |
| lazygit.nvim | `LazyGit()`, a terminal in a popup window |
| auto-dark-mode.nvim | `config/darkmode.vim`, polling `defaults read` |
| render-markdown.nvim | vim-markdown, with `conceallevel=2` |
| markdown-preview.nvim | same plugin; it supports Vim |
| nvim-web-devicons | vim-devicons |
| telescope-undo | undotree |
| nvim-dap | vimspector, behind `enableDebugger` |
| typescript-tools.nvim | typescript-language-server, via vim-lsp |

## Flags in `../vim/default.nix`

- `enableCopilot` (on). nixpkgs marks `copilot.vim` unfree and
  non-redistributable, so `/etc/nix-darwin/flake.nix` allows that one package by
  name. Turning this off removes the need for that allowance.
- `enableDebugger` (off). vimspector needs a Vim built with `+python3`, which
  swaps `pkgs.vim` for an override whose closure is 1.4 GiB rather than 90 MiB.
  `darwinSupport = true` is required in that override or `+clipboard` is lost.

## Two Vim9 traps worth remembering

Both bite only when a function first runs, not when the file is sourced, because
Vim9 compiles `def` bodies lazily.

- **Function names resolve at compile time.** `exists('*FugitiveHead') ?
  FugitiveHead() : ''` fails to compile when fugitive is absent, so the guard
  never gets a chance to return the empty string. `config/statusline.vim` calls
  plugin functions through `call('Name', [])` instead, which resolves at runtime.
  Autoload names with a `#` in them are exempt, so `lsp#...` calls are fine.
- **User commands resolve at compile time too.** `config/format.vim` runs
  `execute 'LspDocumentFormatSync'` rather than naming the command directly,
  since vim-lsp defines it after the vimrc has been read.

To catch both classes at startup while editing this config, append `defcompile`
to a file temporarily: it compiles every `def` in that script immediately.

## No Vim equivalent

- **CodeCompanion.** Lua only.
- **Treesitter.** No Vim port; syntax and indent fall back to Vim's regex files.
- **render-markdown.nvim.** vim-markdown plus `conceallevel=2` is the closest
  thing. Vim 9 virtual text would make a real port possible, but none is written.
- **`laststatus=3`.** Neovim only. Vim 9.2 documents 0, 1 and 2 and silently
  ignores 3, so lualine's `globalstatus` is dropped and each window keeps its own
  status line.
- **`inccommand`.** Neovim only; no live `:s` preview.
- **The cmp buffer source.** `asyncomplete-buffer` ships no license, so nixpkgs
  marks it unfree. `'complete'` feeds the same words to `<C-n>` and `<C-p>`.
- **which-key opening by itself.** No hook for it; the popup is on `<leader>?`.
- **The telescope quickfix picker.** `<leader>ql` opens `:copen`.
- **oil.nvim's editable directory buffer.** netrw is a browser, not a buffer you
  edit and write back; `%`, `d`, `R`, `D` and the `m*` marked-file commands cover
  the same operations.
- **prettierd.** ALE's prettier fixer drives `prettier` itself.
- **dap-python's pytest mappings**, `<leader>Dm` and `<leader>DC`. vimspector has
  no equivalent, and it wants a `.vimspector.json` per project.

## Differences from the Lua config

- `keymaps.lua` bound `<leader>sc` twice, to `command_history` and then to
  `commands`. The second won, so this config has `:Commands`.
- The markdown autocommands in `autocommands.lua` matched `*.md` on the
  `FileType` event, which compares against the filetype name rather than the file
  name, so they never fired. Those settings live in `after/ftplugin/markdown.vim`
  now, where Vim applies and drops them per buffer.
- `yamllint` was listed as a yaml formatter in `conform.lua`, but it only lints,
  so yaml is formatted by `yamlfmt` alone. The `terragrunt` and `liquidsoap`
  entries are dropped: neither formatter is installed.
- LSP servers are registered only when their binary is on `PATH`, so this config
  works unchanged on a machine with a different set of toolchains installed.
