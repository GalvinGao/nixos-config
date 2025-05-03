{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    morlana = {
      url = "github:ryanccn/morlana";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
  {
    nix-darwin,
    nixpkgs,
    ...
  }@inputs:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Galvin-MacBook-Pro
    darwinConfigurations = {
      "Galvin-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/mbp-darwin ];
      };
    };
  };
}
