{ pkgs, ... }:

{
  imports = [
    # TODO: Organize these in directories; e.g. plugins
    ./lsp.nix
    ./tree-sitter.nix
    ./completion.nix
    ./oil.nix
    ./lualine.nix
    ./gitblame.nix
    ./keymappings.nix
    ./options.nix
    ./telescope.nix
    ./autocommands.nix
    ./gitblame.nix
    ./markdown-preview.nix
    ./conform.nix
    ./surround.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.stylua
    pkgs.lua-language-server
    pkgs.vale
    pkgs.nixfmt-rfc-style
  ];

  programs.nixvim = {
    enable = true;
    colorschemes.everforest.enable = true;

    # Default plugins
    plugins.web-devicons.enable = true;
    plugins.which-key.enable = true;
  };
}
