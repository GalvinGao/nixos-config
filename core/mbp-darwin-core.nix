{ pkgs, ... }:

{
  imports = [
    ./darwin
  ];

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    nano

    terminal-notifier
  ];

  # Determinate Nix manages the Nix installation on this host, so nix-darwin
  # must not touch it. This makes nix.* settings (gc, optimise, experimental
  # features, etc.) unavailable — configure them via Determinate instead.
  nix.enable = false;

  # darwin-uninstaller evaluates a *fresh* darwin system (eval-config.nix with
  # only nixpkgs.source) that never sees this host's nixpkgs.overlays, so the
  # nixos-render-docs wrapper below can't reach its nested manual build — it
  # keeps hitting the removed --toc-depth flag. Disable the (rarely used)
  # uninstaller tool so that nested system is never built. Re-enable once
  # upstream nix-darwin migrates to --sidebar-depth.
  system.tools.darwin-uninstaller.enable = false;

  system.defaults = {
    # Dock
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.mru-spaces = true;
    dock.largesize = 41;
    dock.tilesize = 44;
    dock.magnification = false;
    dock.orientation = "bottom";
    dock.wvous-tl-corner = 2;
    dock.wvous-tr-corner = 4;
    dock.wvous-bl-corner = 14;
    dock.wvous-br-corner = 5;
    # Dock tile lists (persistent-apps / persistent-others) are host-specific
    # and declared in each host's thin shell under hosts/darwin/<host>/.

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

    # Keyboard — fast repeat, no accent-popup on hold so keys repeat.
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
    NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;

    # Mission Control / Spaces — switch to space containing the activated app.
    NSGlobalDomain.AppleSpacesSwitchOnActivate = true;

    # Trackpad
    trackpad.Clicking = true;
    trackpad.Dragging = false;
    trackpad.TrackpadRightClick = true;
    trackpad.TrackpadThreeFingerDrag = false;
    trackpad.FirstClickThreshold = 0;
    trackpad.SecondClickThreshold = 0;
    NSGlobalDomain."com.apple.trackpad.scaling" = 0.875;
    NSGlobalDomain."com.apple.trackpad.forceClick" = true;

    # Screenshot
    screencapture.type = "display";
    screencapture.target = "file";
    screencapture.disable-shadow = true;
    screencapture.show-thumbnail = true;

    # Menu Bar Clock
    menuExtraClock.IsAnalog = true;
    menuExtraClock.ShowAMPM = true;
    menuExtraClock.ShowDate = 2;
    menuExtraClock.ShowDayOfWeek = false;

    # Window Manager
    WindowManager.HideDesktop = true;

    CustomSystemPreferences = {
      "com.apple.Music" = {
        userWantsPlaybackNotifications = false;
      };
    };

    CustomUserPreferences = {
      # Accessibility → Zoom. Ctrl+scroll toggles zoom; smooth scaling.
      # Settings app may need to be relaunched for these to display.
      "com.apple.universalaccess" = {
        closeViewScrollWheelToggle = true;
        closeViewSmoothImages = true;
        closeViewZoomIndividualDisplays = true;
        closeViewZoomScreenShareEnabledKey = true;
        closeViewHotkeysEnabled = false;
      };

      # Finder browser toolbar — items, order, icon-only display mode.
      # `TB Display Mode` 2 = icon only. Run `killall Finder` after a
      # switch to pick up changes immediately.
      "com.apple.finder" = {
        "NSToolbar Configuration Browser" = {
          "TB Default Item Identifiers" = [
            "com.apple.finder.BACK"
            "com.apple.finder.SWCH"
            "NSToolbarSpaceItem"
            "com.apple.finder.ARNG"
            "com.apple.finder.SHAR"
            "com.apple.finder.LABL"
            "com.apple.finder.ACTN"
            "NSToolbarSpaceItem"
            "com.apple.finder.SRCH"
          ];
          "TB Display Mode" = 2;
          "TB Icon Size Mode" = 1;
          "TB Is Shown" = 1;
          "TB Item Identifiers" = [
            "com.apple.finder.BACK"
            "com.apple.finder.SWCH"
            "NSToolbarSpaceItem"
            "com.apple.finder.ACTN"
            "com.apple.finder.SHAR"
            "com.apple.finder.NFLD"
            "com.apple.finder.INFO"
            "com.apple.finder.TRSH"
            "com.apple.finder.SRCH"
          ];
          "TB Size Mode" = 1;
        };
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

      # nushell 0.112 SHLVL tests fail inside the Nix sandbox on macOS.
      # Pulled in transitively via bat-extras -> batgrep.
      nushell = prev.nushell.overrideAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
      });

      # nix-darwin master (a1fa429, == HEAD) still passes `--toc-depth` and
      # `--chunk-toc-depth` to nixos-render-docs when building darwin-manual-html,
      # but nixpkgs-unstable removed both flags in favour of `--sidebar-depth`,
      # breaking the build. Wrap the tool to translate the removed flags so the
      # manual + manpages still build (a duplicate --sidebar-depth is harmless;
      # last value wins). Drop this overlay once upstream nix-darwin migrates.
      nixos-render-docs = prev.writeShellScriptBin "nixos-render-docs" ''
        args=()
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --toc-depth | --chunk-toc-depth) args+=(--sidebar-depth "$2"); shift 2 ;;
            *) args+=("$1"); shift ;;
          esac
        done
        exec ${prev.nixos-render-docs}/bin/nixos-render-docs "''${args[@]}"
      '';
    })
  ];

  users.users.galvin = {
    name = "galvin";
    home = "/Users/galvin";
  };

}
