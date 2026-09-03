# Emacs config

The Neovim config ported to Emacs 30, for evaluating Emacs plus Evil against the
Vim 9 config in `../vim-config`. `../emacs/default.nix` installs it.

Built up from nothing rather than from Doom or Spacemacs, because the point of
the exercise is to see what the editor does on its own.

## The package count, which is the whole argument

The Vim config needs **26 third-party plugins**. This needs **seven**, three of
which are Evil:

| Package | Why Emacs cannot do it alone |
| --- | --- |
| `evil` | Emacs ships `viper`, which emulates vi, not Vim: no text objects, no visual block, no operator composition |
| `evil-collection` | bindings for modes Evil does not cover: Dired, help, compilation, the debugger |
| `evil-surround` | vim-surround |
| `haskell-mode` | Emacs ships no Haskell mode, and Eglot needs a major mode to attach to |
| `dape` | DAP client. Needs nothing outside Emacs, unlike vimspector |
| `nix-mode` | Emacs ships no Nix mode, and this repo is mostly Nix |
| `markdown-mode` | Emacs 30 ships no markdown mode either; Emacs 31 has a built-in `markdown-ts-mode` |

Everything else came out of the box:

| Vim plugin | Emacs built-in |
| --- | --- |
| vim-lsp, asyncomplete ×3 | Eglot, `completion-at-point`, `completion-preview-mode` |
| ale | `flymake`, plus `bk-format.el` for the fixers |
| netrw (and oil.nvim before it) | Dired, and `wdired` for the editable listing |
| fzf.vim, fzf-wrapper | `project.el`, `fido-vertical-mode` |
| vim-fugitive, git-messenger | `vc-git`, `vc-annotate`, `vc-print-log` |
| vim-which-key | `which-key`, and it opens by itself |
| vim-commentary | `comment-or-uncomment-region`, wrapped in an Evil operator |
| vim-repeat | `repeat-mode` |
| vim-sleuth | `editorconfig-mode` |
| undotree | Emacs undo is already a tree; `undo-redo` |
| lightline | `mode-line-format`, see `bk-modeline.el` |
| everforest | hand written, see below |
| vim-markdown | `markdown-mode`, or `markdown-ts-mode` on Emacs 31 |
| nvim-treesitter | `treesit` |

## The colour scheme

`lisp/everforest-palette.el` holds the hard dark and hard light palettes,
transcribed from `everforest#get_palette` in sainnhe/everforest — the same
colours the Neovim and Vim configs use, since `g:everforest_background` was
`hard`. `themes/everforest-dark-theme.el` and its light twin apply them.

Written by hand because nixpkgs has no Emacs everforest package, and because a
theme is a good first thing to write when the point is learning to extend the
editor. Roughly 120 faces: syntax, mode line, Dired, Flymake, Eglot, diffs, Org,
completion, which-key.

`bk-theme.el` follows the system appearance. A GUI Emacs on macOS gets a real
hook, `ns-system-appearance-change-functions`, which is better than the 30-second
poll the Vim config has to use; in a terminal frame it falls back to the same
poll.

## Autoloads, which Nix does not load for you

`early-init.el` leaves package.el's startup activation **on**. That looks wrong
in a Nix setup and is not.

Nix puts every package on the `load-path`, but the `site-start.el` nixpkgs
generates does only that: it never reads any package's `*-autoloads.el`.
package.el's activation is what does that, and autoloads are what register
`nix-mode` in `auto-mode-alist`. With activation off, `.nix` files open in
`fundamental-mode` while `nix-mode` sits there loadable and unused. Anything this
config `require`s explicitly still works, which is why Haskell looked fine and
Nix did not.

Nothing is ever fetched: Nix owns the package set. `package-user-dir` points into
the cache so no `elpa` tree appears in this directory.

Worth knowing when testing: `emacs --batch -l init.el` does **not** run that
activation, so modes look broken in batch and are fine in a real session.

## Layout

`~/.config/emacs` stays a real directory that home-manager owns, because Emacs
writes plenty into it. Only `early-init.el`, `init.el`, `lisp/` and `themes/` are
links into this repo. `init.el` then redirects the noisy state — auto-saves,
backups, `recentf`, `savehist`, `eln-cache`, `custom.el` — to `~/.cache/emacs`,
so nothing generated lands in version control. That is the same lesson as
`~/.vim/after`, where everforest wrote a syntax cache into the repo.

| File | From |
| --- | --- |
| `early-init.el` | GC tuning, UI off before the first frame |
| `init.el` | `init.lua` |
| `lisp/bk-options.el` | `lua/vim/options.lua` |
| `lisp/bk-keys.el` | `lua/vim/keymaps.lua` |
| `lisp/bk-evil.el` | modal editing, and the `gc` operator |
| `lisp/bk-theme.el` | `colorschemes.lua`, `auto-dark-mode.lua` |
| `lisp/bk-modeline.el` | `lualine.lua` |
| `lisp/bk-lsp.el` | `lsp.lua` |
| `lisp/bk-completion.el` | `completion.lua`, `telescope.lua` |
| `lisp/bk-format.el` | `conform.lua` |
| `lisp/bk-dired.el` | `oil.lua` |
| `lisp/bk-git.el` | `gitblame.lua`, `lazygit.lua` |
| `lisp/bk-todo.el` | `todo-comments.lua` |
| `lisp/bk-haskell.el` | the haskell block of `lsp.lua` |
| `lisp/bk-debug.el` | `debugging.lua` |

## Two bindings that changed, and why

Emacs keymaps reject a binding that is also the prefix of another one. Vim allows
it and resolves the ambiguity by waiting out `'timeoutlen'`. Two mappings from
`keymaps.lua` are therefore impossible as written:

- `<leader>cc` (close quickfix) collided with `<leader>c`. Dropped; `q` closes a
  results window, via evil-collection.
- `<leader>dd` (end debug session) collided with `<leader>d` for diagnostics. It
  is `<leader>Dq` now, so every debugger key sits under `D`.

`<leader>?` is gone too, but as an improvement: `which-key` opens on its own
after `which-key-idle-delay`, which is what which-key.nvim did and vim-which-key
could not.

## What is worse than the Vim config

- **Eglot has no codeLens**, in Emacs 30.2 or 31.1: `:codeLensProvider` appears
  once in each, in the list of capabilities you can ignore. This costs less than
  it sounds like, because most of what HLS exposes as a lens it also exposes as a
  code action, which Eglot handles fully. See "Code lenses" below.
- **No persistent undo.** Vim's `'undofile'` has no built-in equivalent; undo
  dies with the session. Emacs undo is a tree rather than a line, which is what
  undotree wanted, but it is not written to disk.
- **No gutter diff marks.** vim-gitgutter and mini.diff would need `diff-hl`.
  `vc-diff` shows the same information a different way.
- **No live markdown preview.** `markdown-preview.nvim` has no counterpart, so
  `<leader>pm` is unbound. `M-x eww-open-file` renders built HTML.
- **`cursorcolumn`** has no built-in equivalent and is not ported.
- **prettierd.** `bk-format.el` drives `prettier` itself, as ALE did.

## Code lenses, and what that actually costs

HLS offers most lens features as code actions too, and Eglot filters action
kinds by prefix, so `quickfix` catches the sub-kinds. Eglot also sends the
Flymake diagnostics at point along with the request, which is what a
diagnostic-attached fix needs.

| HLS feature | Kind | Works in Eglot |
| --- | --- | --- |
| Import a name that is not in scope | code action, `quickfix`, hls-refactor-plugin | yes, `cl` |
| Make import lists fully explicit | code action `quickfix.literals.style`, and a lens | yes, `cl` |
| Refine import | code action `quickfix.import.refine`, and a lens | yes, `cl` |
| Change type signature | code action `quickfix`, hls-change-type-signature | yes, `cl` |
| Organize imports | code action `source.organizeImports` | yes, `co` |
| **Add type signature** | **lens only**, ghcide | **no** |

So auto-imports work. The one genuine loss is the inferred-type-signature lens,
which ghcide provides as a lens and nothing else; HLS issue #1099, "Code action:
Add missing signatures", is still a request. Two partial substitutes:

- `K` shows the inferred type through Eldoc and hover, so the information is
  there, just not rendered above the binding with a click to insert it.
- Building with `-Wmissing-signatures` makes GHC put the inferred signature in
  the warning text, which then shows up in Flymake where it can be copied.

If the inline display is worth having, there are three routes, in order of how
well they fit this config:

1. Write it. Code lens is three requests: `textDocument/codeLens`,
   `codeLens/resolve` and `workspace/codeLens/refresh`, drawn as overlays.
   [A published gist](https://gist.github.com/Gavinok/fa23bbea7f44725eb633c002a8aa803a)
   does it in about 150 lines, though it calls the now-deprecated
   `eglot-execute`.
2. `lsp-mode` with `lsp-lens-mode`, which supports lenses properly. It is a much
   larger package than Eglot and would undo the point of this config.
3. `eglot-x` does **not** help here: it adds rust-analyzer's runnables, not
   general lens support.

**If auto-import stops working, suspect GHC rather than Emacs.** A
[thread on the Haskell Discourse](https://discourse.haskell.org/t/resolved-missing-hls-features-in-emacs/8660)
that started as "HLS features missing in Emacs" turned out to be a GHC version
problem: the import and hole-fit actions worked on GHC 9.4 and stopped on 9.8.
Check the HLS plugin support matrix for the GHC in use.

## What is better

- Dired plus `wdired`: `C-x C-q` makes the listing editable, so renames are text
  edits and deletions are killed lines, then `C-c C-c` applies. That is the
  oil.nvim feature lost in the move to netrw, built in since the 1980s.
- `haskell-interactive-mode`: a GHCi session per Cabal project with errors in the
  REPL output becoming jumpable source locations. The Vim side has nothing close.
- `dape` needs no `+python3` build, so DAP is on by default here. In Vim it cost
  a 1.4 GiB closure and stayed off.
- `C-h f`, `C-h k` and `M-.` read the source of anything, including the C
  primitives. This is the self-documenting part, and it is the reason to be here.

## Terminal only

`../emacs/default.nix` installs `emacs-nox`, the build with no GUI code at all.
The default `pkgs.emacs` on darwin is a Cocoa build, so running `emacs` in a
terminal makes it negotiate with the macOS window server and open a window
somewhere else, which looks exactly like a hang. There is no such path here.

```sh
e            # emacsclient --tty, starts a daemon on first use; opens instantly
emacs        # a fresh instance, about 1 second
```

`e` is `emacsclient --tty --alternate-editor=""`. The empty alternate editor is
what makes it start a daemon if none is running, so there is no launchd agent to
manage and nothing running until it is first wanted. Good fit for tmux, where the
alternative is paying startup in every pane.

### The clipboard, which needs help

A GUI Emacs talks to the system clipboard for free. A terminal frame does not:
`display-selections-p` is nil and `interprogram-cut-function` is
`gui-select-text`, which does nothing without a window system. Left alone, every
Evil yank and `SPC yf` would stay inside Emacs. Vim got this from `+clipboard`.

`lisp/bk-clipboard.el` wires the kill ring to `pbcopy` and `pbpaste`, picking
`wl-copy` or `xclip` instead when they are what is available, so the Linux
machine works too. The write is synchronous on purpose: with `start-process`,
quitting right after a yank loses it.

### tmux

Verified working in tmux 3.4: 24-bit colour reaches Emacs
(`display-color-cells` returns 16777216) and the everforest palette renders
exactly.

Two settings do that, both already in the tmux config for Neovim's benefit:

- `COLORTERM=truecolor`, which is how Emacs decides a terminal has 24-bit
  colour.
- `set -sg escape-time 10`. Without a low escape time, ESC in a terminal is read
  as a Meta prefix and leaving Evil's insert state lags.

One gap worth closing: the true-colour override is written for Ghostty only,

```
set-option -sa terminal-overrides ',xterm-ghostty:RGB'
```

so it does not match kitty's `xterm-kitty`. On tmux 3.2 and newer this covers
every outer terminal at once:

```
set -as terminal-features ',*:RGB'
```

## Trying it

Worth checking first: `SPC` then wait for which-key, `gcc` on a line, `SPC o` for
Dired, `C-x C-q` in Dired to edit the listing, `y` then paste into another app to
confirm the clipboard, and `M-x haskell-mode` in a Cabal project for the REPL.
