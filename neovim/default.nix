{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # LazyVim deps
    pkgs.ripgrep
    pkgs.fd
  ];

  programs.neovim = { 
    enable = true;
  };

  xdg.configFile.nvim = {
    source = ./.;
    recursive = true;
  };
}
