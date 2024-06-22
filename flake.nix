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
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }:
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
          modules = [ ./home.nix ];
        };
      };
    };
}
