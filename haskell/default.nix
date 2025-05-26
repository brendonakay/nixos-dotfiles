{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Haskell
    ghc
    ghcid
    ormolu
    cabal-install
    hlint
    # haskell-language-server
    haskellPackages.hakyll
  ];
}
