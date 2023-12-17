{ pkgs, ... }:

{ 
  home.packages = with pkgs; [
    ocamlPackages.ocaml
    ocamlPackages.dune_3
    ocamlPackages.findlib
    ocamlPackages.utop
    ocamlPackages.odoc
    ocamlPackages.ocaml-lsp
    ocamlformat
    opam
  ];
}
