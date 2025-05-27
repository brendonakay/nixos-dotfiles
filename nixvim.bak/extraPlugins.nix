{ pkgs, ... }:

{
  # Install via Nix Pkgs
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.mini-diff ];

  # Configure the plugin
  programs.nixvim.extraConfigLua = "require('mini.diff').setup({})";
}
