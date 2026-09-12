# Emacs config

## Packages

The Vim config needs **26 third-party plugins**. This needs **ten**, three of
which are
Evil:

| ----------------- | ----------------------------------------------------------------------------------------------------------------- |
| `evil` | Emacs ships `viper`, which emulates vi, not Vim: no text objects, no visual block, no operator composition |
| `evil-collection` | bindings for modes Evil does not cover: Dired, help, compilation, the debugger |
| `evil-surround` | vim-surround |
| `haskell-mode` | Emacs ships no Haskell mode, and Eglot needs a major mode to attach to |
| `dape` | DAP client. Needs nothing outside Emacs, unlike vimspector |
| `nix-mode` | Emacs ships no Nix mode, and this repo is mostly Nix |
| `markdown-mode` | Emacs 30 ships no markdown mode either; Emacs 31 has a built-in `markdown-ts-mode` |
| `magit` | Built-in VC covers blame, log and diff, but nothing built in comes close for staging, rebasing or reading history |
| `corfu` | The one built-in gap in editing itself: nothing draws a completion menu at point. See below |
| `corfu-terminal` | Corfu's popup is a child frame, which a terminal frame cannot host. Redraws it with overlays through `popon` |

Everything else came out of the box:

| Vim plugin                     | Emacs built-in                                             |
| ------------------------------ | ---------------------------------------------------------- |
| vim-lsp, asyncomplete ×3       | Eglot and `completion-at-point`, drawn by Corfu            |
| ale                            | `flymake`, plus `bk-format.el` for the fixers              |
| netrw (and oil.nvim before it) | Dired, and `wdired` for the editable listing               |
| fzf.vim, fzf-wrapper           | `project.el`, `fido-vertical-mode`                         |
| vim-fugitive, git-messenger    | `vc-annotate`, `vc-print-log`; Magit for the rest          |
| vim-which-key                  | `which-key`, and it opens by itself                        |
| vim-commentary                 | `comment-or-uncomment-region`, wrapped in an Evil operator |
| vim-repeat                     | `repeat-mode`                                              |
| vim-sleuth                     | `editorconfig-mode`                                        |
| undotree                       | Emacs undo is already a tree; `undo-redo`                  |
| lightline                      | `mode-line-format`, see `bk-modeline.el`                   |
| everforest                     | hand written, see below                                    |
| vim-markdown                   | `markdown-mode`, or `markdown-ts-mode` on Emacs 31         |
| nvim-treesitter                | `treesit`                                                  |

## The mode line

Built to match lualine, and laid out the same way:

```
 NORMAL   work-env  /Users/bkay/Workspace/xoi-backend/app/main.py    E2 W1  xoi-backend   utf-8  unix   Python  Top  42:7
```

Left: Evil state on a state-coloured block, the branch, then the **full** path,
not the project-relative one. The path is elided from the left when the window is
too narrow, so the file name survives rather than the leading directories.

Right: Flymake counts, the Eglot server, a macro recording indicator, then
encoding, line ending, major mode, scroll position and line:column.

Powerline separators and the branch glyph come from Nerd Font, which both kitty
and Ghostty are already configured with here. They live in one place,
`bk-modeline-glyphs`, so any of them can become plain text:

```elisp
(setf (alist-get 'branch bk-modeline-glyphs) "git:")
```

Per-language filetype icons would need the `nerd-icons` package, so the major
mode is shown as text instead.

Two things worth knowing about how it gets the branch. For file buffers it reads
`vc-mode`, which Emacs keeps current. Dired and other directory buffers have no
`vc-mode`, so it reads `.git/HEAD` directly, handling the case where `.git` is a
file pointing at a worktree's real gitdir, and caches the result for three
seconds. That is a small file read rather than a git subprocess, because this
code runs on every redisplay: measured at 0.043 ms per render.

## The completion popup, and why it needed a package

Everything else here replaced a Vim plugin with something already in Emacs. This
is the one place that argument runs out. The built-ins do complete -- Eglot
installs a `completion-at-point' function and `dabbrev' covers buffer words --
but nothing draws the result at point. `tab-always-indent' set to `complete'
opens the `*Completions*' window at the bottom of the frame, and
`completion-preview-mode' shows one candidate inline with nothing to move
through. Neither is what cmp did, and no amount of configuration turns either
into it.

Corfu is that and nothing more: the same completion-at-point functions, drawn in
a popup. It used to be unusable here, because it renders in a child frame and
`emacs-nox` has no window system. Emacs 31 supports child frames on a tty, and
corfu already tests for it:

```elisp
(or (display-graphic-p) (featurep 'tty-child-frames))
```

so the popup renders in the terminal.

The keys took one extra step. Vim completes with C-n and C-p in insert mode, and
Evil binds both to `evil-complete-next', a dabbrev expansion that changes the
buffer with no menu -- which is why pressing them looked like nothing happened
rather than like a missing feature. Corfu's own keymap remaps `next-line' and
`previous-line', so it would take those keys by itself if they ever reached the
global binding. They do not. Evil's state keymaps live in
`emulation-mode-map-alists', which Emacs consults before the
`minor-mode-overriding-map-alist' entry corfu installs, so Evil wins every time
and rebinding inside `corfu-map' would have no effect at all.

So `bk-completion.el` binds them in Evil's insert state instead, to two commands
that move through the popup when it is up and open it when it is not. That last
part is the half Vim users expect and cmp did not need: in Vim, C-n is what
*starts* completion.

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

| File                    | From                                     |
| ----------------------- | ---------------------------------------- |
| `early-init.el`         | GC tuning, UI off before the first frame |
| `init.el`               | `init.lua`                               |
| `lisp/bk-options.el`    | `lua/vim/options.lua`                    |
| `lisp/bk-keys.el`       | `lua/vim/keymaps.lua`                    |
| `lisp/bk-evil.el`       | modal editing, and the `gc` operator     |
| `lisp/bk-theme.el`      | `colorschemes.lua`, `auto-dark-mode.lua` |
| `lisp/bk-modeline.el`   | `lualine.lua`                            |
| `lisp/bk-lsp.el`        | `lsp.lua`                                |
| `lisp/bk-completion.el` | `completion.lua`, `telescope.lua`        |
| `lisp/bk-format.el`     | `conform.lua`                            |
| `lisp/bk-dired.el`      | `oil.lua`                                |
| `lisp/bk-git.el`        | `gitblame.lua`, `lazygit.lua`            |
| `lisp/bk-todo.el`       | `todo-comments.lua`                      |
| `lisp/bk-haskell.el`    | the haskell block of `lsp.lua`           |
| `lisp/bk-debug.el`      | `debugging.lua`                          |

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

| HLS feature                        | Kind                                              | Works in Eglot |
| ---------------------------------- | ------------------------------------------------- | -------------- |
| Import a name that is not in scope | code action, `quickfix`, hls-refactor-plugin      | yes, `cl`      |
| Make import lists fully explicit   | code action `quickfix.literals.style`, and a lens | yes, `cl`      |
| Refine import                      | code action `quickfix.import.refine`, and a lens  | yes, `cl`      |
| Change type signature              | code action `quickfix`, hls-change-type-signature | yes, `cl`      |
| Organize imports                   | code action `source.organizeImports`              | yes, `co`      |
| **Add type signature**             | **lens only**, ghcide                             | **no**         |

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

### Emacs is not a terminal emulator

`term.el` is a weak one. lazygit inside it comes out with broken panel borders
and box-drawing characters printed as raw octal escapes, because term.el does not
decode the UTF-8 the TUI emits. `eat` renders TUIs properly in pure elisp, and
`vterm` better still with a compiled module, but both are packages and neither
beats handing the job to something that already is a terminal.

So `SPC lg`, the old lazygit key, now opens **Magit** — Emacs buffers, nothing to
mangle, and evil-collection already supplies its vim bindings. `SPC gt` runs
lazygit in a new **tmux window**, where it looks the way it should. It refuses
with a clear message when `$TMUX` is unset rather than falling back to term.

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

## A language server in someone else's userspace

Some work has to build against a userspace that is not this machine's, because
something downstream -- a grader, a CI image, a deployment target -- is the thing
that actually has to accept the code. What matters then is what that image's
compiler makes of it, not what this machine's does. On an Ubuntu 22.04 image
against this system that is gcc 11.4 and glibc 2.35 versus gcc 15.3 and glibc
2.42, which is wide enough to matter: gcc 15 defaults to C23 and makes implicit
function declarations a hard error. `lisp/bk-container.el` puts clangd where the
build is.

The kernel is not part of the difference, which is worth saying because `uname`
makes it look like it is. A container shares the host kernel, so the image
reports this one:

```
host       Linux nixos        6.18.48 #1-NixOS SMP PREEMPT_DYNAMIC ... x86_64 GNU/Linux
container  Linux 1966b33b7e8f 6.18.48 #1-NixOS SMP PREEMPT_DYNAMIC ... x86_64 x86_64 x86_64 GNU/Linux
```

Same kernel, down to the `#1-NixOS` build string. The two lines differ in the
hostname, which is the container id, and in three `x86_64` where there is one:
`uname -a` prints the processor and hardware platform only when they are known,
and NixOS's coreutils reports both as `unknown` while Ubuntu's reports `x86_64`.
Nothing about syscalls, `/proc` or scheduling differs. The userspace above the
kernel does, and that is the half clangd reads.

Emacs stays on this side and edits the bind-mounted files as ordinary local
files. Only clangd is remote, over `docker exec`, which `bk-container-clangd`
returns as an Eglot contact for the C modes. `bk-container-alist` maps a
directory to the image whose container serves it; anything under that directory
is covered by the one entry, so several repos that share a target image need only
one. Everything below is written against two names:

```
ROOT=<the directory holding the repos>
IMAGE=<the image tag built below>
```

The one thing that needs care is paths. Eglot sends absolute paths and they are
this machine's, because the buffer really is a local file; clangd on the other
side needs the same file to be reachable by that same name. The cheap way to
guarantee it is to bind-mount at the identical path on both sides:

```
-v "$ROOT:$ROOT"
```

Mount the directory that holds the repos rather than one repo.
`bk-container--mountpoint` takes the deepest mount containing a directory and
appends the remainder, so a single mount covers every repo under it.

Where the paths cannot be made to match -- an image already running with the
tree on `/data`, say -- `bk-container--link` symlinks the host path onto the
mount inside the container so both names resolve, and is a no-op when they
already agree. Without one or the other, clangd still parses the buffer text
(`didOpen` carries it) but nothing that needs the path works:

```
path not resolvable   '_probe.h' file not found
                      Use of undeclared identifier 'PROBE_LOCAL_HEADER_FOUND'
path resolvable       no diagnostics
```

A `_Static_assert` on `__GLIBC_MINOR__` is the quickest check that the right
server answered: against the container it passes, and against this machine's
clangd it fails with `'42 == 35'`.

The image needs clangd in it, and an image that came from somewhere else should
not be edited to get it, so stack one on top:

```dockerfile
FROM <the upstream image>
RUN apt-get update \
 && apt-get install -y --no-install-recommends clangd bear \
 && rm -rf /var/lib/apt/lists/*
```

```
docker build -f Dockerfile.dev -t "$IMAGE" .
docker run -dit --name "$IMAGE" \
  --user $(id -u):$(id -g) -e HOME=/tmp \
  -v "$ROOT:$ROOT" -w "$ROOT" "$IMAGE"
```

`--user` is not optional in practice. The image runs as root and a bind mount
carries uids through unchanged, so a build started in the container writes
root-owned binaries into the working tree on this side. `HOME` moves because
`/root` is not writable as an ordinary uid and bear wants a cache directory.

`bear -- make` inside the container writes the `compile_commands.json` clangd
wants, and it has to be generated there: the flags and include paths only mean
anything next to the compiler that produced them. Where each directory builds on
its own there is one file per directory, and clangd takes the nearest.

`<leader>Cc` compiles in the container and `<leader>Cs` opens a shell in it, in a
tmux window, for the same reason `<leader>gt` does.

One Eglot detail worth keeping, because it is not in the manual. A function
contact is called from two places with different arities: `eglot--connect` calls
it with no arguments, while `eglot--guess-contact` reads `func-arity` and calls
it with (INTERACTIVE PROJECT) unless the maximum arity is exactly 1. A nullary
function loads without complaint and then fails with wrong-number-of-arguments on
the first file opened, so `bk-container-clangd` takes two optional arguments.

## Trying it

Worth checking first: `SPC` then wait for which-key, `gcc` on a line, `SPC o` for
Dired, `C-x C-q` in Dired to edit the listing, `y` then paste into another app to
confirm the clipboard, and `M-x haskell-mode` in a Cabal project for the REPL.
