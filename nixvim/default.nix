{ pkgs, ... }:

{
  imports = [
    # TODO: Organize these in directories; e.g. plugins
    ./autocommands.nix
    ./codecompanion.nix
    ./completion.nix
    ./conform.nix
    ./copilot-vim.nix
    ./extraPlugins.nix
    ./gitblame.nix
    ./gitblame.nix
    ./keymappings.nix
    ./lsp.nix
    ./lualine.nix
    ./markdown-preview.nix
    ./oil.nix
    ./options.nix
    ./sleuth.nix
    ./surround.nix
    ./telescope.nix
    ./tree-sitter.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.stylua
    pkgs.lua-language-server
    pkgs.vale
    pkgs.nixfmt-rfc-style
    pkgs.prettierd
  ];

  programs.nixvim = {
    enable = true;
    colorschemes.everforest.enable = true;

    # Default plugins
    plugins.web-devicons.enable = true;
    plugins.which-key.enable = true;
  };
}
