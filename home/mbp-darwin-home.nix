{ inputs, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Back up conflicting dotfiles on activation instead of refusing to switch.
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

    users.galvin = {
      imports = [
        ./terminal/zsh.nix
        ./terminal/starship.nix
        ./terminal/atuin.nix
        ./terminal/git.nix
        ./terminal/htop.nix
        ./terminal/duckdb.nix
        ./terminal/gpg.nix
        ./terminal/npmrc.nix
        ./rime.nix
      ];

      home.username = "galvin";
      home.homeDirectory = "/Users/galvin";
      home.stateVersion = "25.05";

      home.activation.installClaudeCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'export PATH="${pkgs.curl}/bin:/usr/bin:$PATH"; curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash'
      '';

      # Use pkgs.nodejs rather than fnm so activation doesn't depend on the
      # user having a Node version installed yet. Install prefix is ~/.local,
      # which is already on PATH via zsh config.
      home.activation.installCodexCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'export PATH="${pkgs.nodejs}/bin:$PATH"; export npm_config_prefix="$HOME/.local"; npm i -g @openai/codex'
      '';

      # Homebrew postgresql@N data dirs are per-version; assign each a unique port (543NN).
      home.activation.configurePostgresPorts = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        for v in 14 16 17 18; do
          conf="/opt/homebrew/var/postgresql@$v/postgresql.conf"
          want="543$v"
          if [ -f "$conf" ] && ! ${pkgs.gnugrep}/bin/grep -qE "^port = $want([[:space:]]|$)" "$conf"; then
            run ${pkgs.gnused}/bin/sed -i -E "s/^#?[[:space:]]*port[[:space:]]*=[[:space:]]*[0-9]+/port = $want/" "$conf"
          fi
        done
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

      # Ghostty — app installed via Homebrew cask; config is file-managed.
      home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
        force = true;
        text = ''
          maximize = true
          window-padding-x = 4
          window-padding-y = 4
          background-opacity = 0.95
          background-blur = 20
          minimum-contrast = 4
          background = #0f0f0f
          font-size = 16
          font-family = "JetBrainsMono Nerd Font"
          adjust-cell-height = 8
          keybind = shift+enter=text:\n
          keybind = alt+backspace=text:\x1b\x7f
          keybind = global:alt+grave_accent=toggle_quick_terminal
          quick-terminal-position = bottom
          quick-terminal-animation-duration = 0.1
        '';
      };

      home.packages = with pkgs; [
        yazi
        just
        pixman
        p7zip # 7-Zip file archiver
        rsync

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
        gh # GitHub CLI
        cargo
        rustc
        go
        golangci-lint
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
        k9s
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
