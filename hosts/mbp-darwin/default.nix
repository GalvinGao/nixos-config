{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./../../core/darwin
  ];

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    nano

    nil
    nixfmt-rfc-style

    autojump
    starship
    nixfmt

    xxHash
    grpc
    stripe-cli
    consul
    maestro
    openfga
    supabase-cli
    _1password-cli

    # Development
    openjdk
    apktool
    argocd
    aria2
    awscli
    dive
    doctl
    duckdb
    erlang
    exiftool
    fastfetch
    eza
    fastlane
    fnm
    git
    git-lfs
    go
    grafana
    grpcurl
    hashcat
    htop
    imagemagick
    iperf
    iperf3
    jq
    k6
    jmeter
    kubectl
    mtr
    ouch
    pandoc
    pngquant
    postgresql
    rclone
    rabbitmq-server
    redis
    speedtest-cli
    tmux
    tree
    wget
    yq
    yt-dlp
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = 6;

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
  };

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
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      programs.zsh = {
        enable = true;
        syntaxHighlighting = {
          enable = true;
        };
      };
      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batgrep
        ];
      };

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
