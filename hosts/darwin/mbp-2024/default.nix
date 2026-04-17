{ inputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./../../../core/mbp-darwin-core.nix
    ./../../../home/mbp-darwin-home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "galvin";
  system.stateVersion = 6;
}
