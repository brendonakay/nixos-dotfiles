# NixOS Dotfiles

Home Manager and Flakes

## Nixvim

My main editor is NeoVim configured by Nix. This is accomplished using
[Nixvim](https://github.com/nix-community/nixvim).

Thanks to the many examples in [this
list](https://nix-community.github.io/nixvim/user-guide/config-examples.html)
for helping me build my own config.

# FIX

- [ ] Unfree with home-manager and nixvim.
  - Need to use `export NIXPKGS_ALLOW_UNFREE=1` and `--impure` to build
    home-manager.
  - Even though I have unfree set in `configuration.nix` and in the home-manager
    flake.

# TODO

- [ ] Configure laziness for Nixvim.
- [ ] Migrate to i3 window manager.
- [ ] Pimp out `tmux` bottom bar.
- [ ] Add a direnv setup to let me know when I'm in a nix shell.
- [x] Add `kitty` config.
- [x] Install `lazygit`.
