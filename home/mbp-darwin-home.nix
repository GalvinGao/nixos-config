{ inputs, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.galvin = {
      imports = [
        ./terminal/zsh.nix
        ./terminal/starship.nix
        ./terminal/atuin.nix
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

        # Migrated from Homebrew brews
        nmap
        kubernetes-helm # brew: helm (nix `helm` is a music synthesizer)
        kubectx
        kubeseal
        zellij
        brotli
        xcbeautify
        bundletool
        ios-deploy
        mongosh
        swiftlint
        swiftformat
        wakatime-cli
        vgmstream
        opencode
        prek
      ];
    };
  };
}
