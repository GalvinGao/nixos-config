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

    terminal-notifier
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = 6;

  system.primaryUser = "galvin";

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = true;
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder._FXSortFoldersFirst = false;
    finder.FXEnableExtensionChangeWarning = false;
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    CustomSystemPreferences = {
      "com.apple.Music" = {
        userWantsPlaybackNotifications = false;
      };
    };
  };

  nixpkgs.overlays = [
    inputs.morlana.overlays.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.galvin = {
      imports = [
        ./../../home/terminal/zsh.nix
        ./../../home/terminal/starship.nix
        ./../../home/terminal/atuin.nix
      ];

      home.username = "galvin";
      home.homeDirectory = "/Users/galvin";
      home.stateVersion = "25.05";

      programs.home-manager.enable = true;
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
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
        just
        pixman
        p7zip # 7-Zip file archiver

        nil
        nixfmt-rfc-style

        autojump
        starship

        xxHash
        grpc
        stripe-cli
        maestro
        openfga
        supabase-cli

        # Development
        openjdk
        apktool
        argocd
        aria2
        cmake
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
        gh # GitHub CLI
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
    };
  };

  users.users.galvin = {
    name = "galvin";
    home = "/Users/galvin";
  };

  nix.gc.automatic = true;
  nix.gc.interval.Hour = 3;
  nix.gc.options = "--delete-older-than 15d";
  nix.optimise.automatic = true;
  nix.optimise.interval.Hour = 4;
}
