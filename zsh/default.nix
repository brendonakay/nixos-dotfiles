{ config, pkgs, ... }:

let
  myAliases = {
    # TODO
  };
in {
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    shellAliases = myAliases;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };    
  };
}
