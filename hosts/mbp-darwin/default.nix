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
    # Dock
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.mru-spaces = true;
    dock.largesize = 41;
    dock.tilesize = 44;
    dock.wvous-tl-corner = 2;
    dock.wvous-tr-corner = 4;
    dock.wvous-bl-corner = 14;
    dock.wvous-br-corner = 5;

    # Finder
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder._FXSortFoldersFirst = false;
    finder.FXEnableExtensionChangeWarning = false;
    finder.FXPreferredViewStyle = "clmv";
    finder.NewWindowTarget = "Home";
    finder.ShowExternalHardDrivesOnDesktop = false;
    finder.ShowRemovableMediaOnDesktop = false;

    # Global
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;

    # Trackpad
    trackpad.Clicking = true;
    NSGlobalDomain."com.apple.trackpad.scaling" = 0.875;

    # Screenshot
    screencapture.type = "display";

    # Menu Bar Clock
    menuExtraClock.IsAnalog = true;
    menuExtraClock.ShowDate = 2;
    menuExtraClock.ShowDayOfWeek = false;

    # Window Manager
    WindowManager.HideDesktop = true;

    CustomSystemPreferences = {
      "com.apple.Music" = {
        userWantsPlaybackNotifications = false;
      };
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          jeepney = pyPrev.jeepney.overridePythonAttrs (old: {
            doCheck = false;
            doInstallCheck = false;
            pythonImportsCheck = [ ];
          });
        }
      );
    })
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

      home.activation.installClaudeCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'export PATH="${pkgs.curl}/bin:/usr/bin:$PATH"; curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash'
      '';

      home.activation.installCodexCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'eval "$(${pkgs.fnm}/bin/fnm env --shell bash)"; npm i -g @openai/codex'
      '';

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
        yazi
        just
        pixman
        p7zip # 7-Zip file archiver

        nil
        nixfmt
        nh

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
        # argocd  # Build fails due to missing git in build sandbox - use Homebrew if needed
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
        speedtest-cli
        tmux
        tree
        wget
        yq
        yt-dlp

        # Migrated from Homebrew
        cloudflared
        consul
        awscli2
        s5cmd
        ffmpeg
        axel
        pkg-config
        httpie
        arp-scan
        asciinema
        ast-grep
        miniserve
        parallel
        pigz
        python313
        inetutils # includes telnet
        watch
        act
        pv

        proto

        # Identified from shell history (not previously declared)
        neovim
        mosh
        natscli # NATS CLI client (nats-server is in homebrew)
        wrk # HTTP benchmarking
        flyctl # Fly.io CLI
        binwalk
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
