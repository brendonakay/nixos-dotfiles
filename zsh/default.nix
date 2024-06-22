{ config, pkgs, ... }:

let
  myAliases = {
    # TODO
  };
in {
  programs.zsh = {
    enable = true;
    autosuggestion = { enable = true; };
    shellAliases = myAliases;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

    initExtra = ''
      eval "$(direnv hook zsh)"
      eval "$(opam env)"
    '';
  };
}
