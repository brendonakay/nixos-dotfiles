{
  description = "Main flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, nixvim, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # create patched nixpkgs
      nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgs;
      };

      # configure pkgs
      pkgs = import nixpkgs-patched {
        inherit system;
        config = { allowUnfree = true;
                   allowUnfreePredicate = (_: true); };
      };
    in {
      home-manager.useGlobalPkgs = true;

      # Home Manager module for Vim. /etc/nix-darwin imports ./vim/default.nix
      # by path rather than through this output, which keeps this flake's nixvim
      # and hyprland inputs out of the darwin lock file.
      homeManagerModules.vim = ./vim/default.nix;
      homeManagerModules.emacs = ./emacs/default.nix;

      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
          specialArgs = { inherit hyprland; };
        };
      };
      homeConfigurations = {
        brendonakay = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            nixvim.homeManagerModules.nixvim
          ];
        };
      };
    };
}
