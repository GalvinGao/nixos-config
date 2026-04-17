{
  description = "Galvin's nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    _1password-shell-plugins.url = "github:1Password/shell-plugins";
  };

  outputs =
    {
      nix-darwin,
      nixpkgs,
      ...
    }@inputs:
    let
      darwinSystems = import ./os/darwin.nix;

      mkConfiguration =
        { systems, mkSystem }:
        builtins.listToAttrs (
          builtins.concatMap (
            sys:
            builtins.map (host: {
              name = host;
              value = mkSystem {
                system = sys.system;
                specialArgs = { inherit inputs; };
                modules = sys.moduleResolver host;
              };
            }) sys.hosts
          ) systems
        );
    in
    {
      darwinConfigurations = mkConfiguration {
        systems = darwinSystems;
        mkSystem = nix-darwin.lib.darwinSystem;
      };

      homeManagerModules = {
        _1password-shell-plugins = inputs._1password-shell-plugins.hmModules.default;
      };
    };
}
