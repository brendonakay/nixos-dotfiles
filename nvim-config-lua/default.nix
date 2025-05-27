{ pkgs, config, ... }:

{
  # Install NeoVim and any other system dependencies.
  # e.g. LSPs, grep, fuzzyfinder...
  home.packages = [
    pkgs.neovim
    pkgs.ripgrep
    pkgs.fd
    pkgs.stylua
    pkgs.lua-language-server
    pkgs.vale
    pkgs.nixfmt-rfc-style
    pkgs.prettierd
    pkgs.typos-lsp
    pkgs.nil
  ];

  # Copy the config directory to the dotfiles directory.
  home.file.".config/nvim" = {
    # TODO: Make this generic per system.
    source = config.lib.file.mkOutOfStoreSymlink "/home/brendonakay/.dotfiles/nvim-config-lua";
  };
}
