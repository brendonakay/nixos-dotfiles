{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # LazyVim deps
    pkgs.ripgrep
    pkgs.fd
    pkgs.stylua
    pkgs.lua-language-server
  ];

  programs.neovim = { 
    enable = true;
  };

  xdg.configFile.nvim = {
    source = ./.;
    recursive = true;
  };
}
