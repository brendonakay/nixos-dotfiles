# NixOS Dotfiles

Home Manager and Flakes

## Nixvim

My main editor is NeoVim configured by Nix. This is accomplished using
[Nixvim](https://github.com/nix-community/nixvim).

Thanks to the many examples in [this
list](https://nix-community.github.io/nixvim/user-guide/config-examples.html)
for helping me build my own config.

## Vim

`vim-config/` is the Neovim config ported to Vim 9, and `vim/default.nix` is
the Home Manager module that installs it. It provides the `vim` command on this
machine, using Vim's conventional `~/.vim` layout. See `vim-config/README.md`
for the plugin mapping and the pieces that have no Vim equivalent.

On the work Mac the module is imported by `/etc/nix-darwin/flake.nix`, which
pulls it in as a `flake = false` input pointing at `vim/`. Rebuild with:

```sh
sudo darwin-rebuild switch --flake /etc/nix-darwin#HKQKRXMT21
```

## Emacs

`emacs-config/` is the same Neovim config ported to Emacs 30 with Evil, for
evaluating Emacs against Vim. `emacs/default.nix` installs it. Both editors are
installed at once; `vim` and `emacs` are independent.

The interesting number: the Vim config needs 26 third-party plugins, this needs
five. Everything else is an Emacs built-in. See `emacs-config/README.md`, which
also lists where Emacs is worse (Eglot has no codeLens, no persistent undo).

# FIX

- [ ] Unfree with home-manager and nixvim.
  - Need to use `export NIXPKGS_ALLOW_UNFREE=1` and `--impure` to build
    home-manager.
  - Even though I have unfree set in `configuration.nix` and in the home-manager
    flake.

# TODO

- [ ] Configure laziness for Nixvim.
- [ ] Add GitSigns (or whatever colors git changes in the left side)
- [ ] Migrate to i3 window manager.
- [ ] Pimp out `tmux` bottom bar.
- [ ] Add a direnv setup to let me know when I'm in a nix shell.
- [ ] Rewrite Nix stuff to use fewer dependencies. Do not nixify NeoVim config.
- [x] Add `kitty` config.
- [x] Install `lazygit`.
