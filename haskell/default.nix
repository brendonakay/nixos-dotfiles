{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Haskell
    ghc
    ghcid
    ormolu
    cabal-install
    hlint
    haskellPackages.hoogle
    # haskell-language-server
    haskellPackages.hakyll
  ];
}
