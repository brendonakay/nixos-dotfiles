{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    pkgs.ripgrep
    pkgs.fd
    pkgs.stylua
    pkgs.lua-language-server
  ];

  # programs.neovim = { 
  #   enable = true;
  # };

  # xdg.configFile.nvim = {
  #   source = ./.;
  #   recursive = true;
  # };
  
  programs.nixvim = {
    enable = true;
    colorschemes.everforest.enable = true;
  };
}
