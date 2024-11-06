{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Haskell
    ghcid
    ormolu
    cabal-install
    hlint
    haskell-language-server
  ];
}
