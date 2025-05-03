{ inputs, pkgs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./../../core/darwin
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    nano

    nil
    nixfmt-rfc-style
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = 6;

  system.defaults.dock.autohide = true;
  system.defaults.dock.mru-spaces = false;
  system.defaults.finder.AppleShowAllExtensions = true;

  nixpkgs.overlays = [
    inputs.morlana.overlays.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    
    users.galvin = {
      home.username = "galvin";
      home.homeDirectory = "/Users/galvin";
      home.stateVersion = "25.05";

      programs.home-manager.enable = true;

      home.packages = with pkgs; [
        morlana
        yazi
      ];

    };
  };

  users.users.galvin = {
    name = "galvin";
    home = "/Users/galvin";
  };
}