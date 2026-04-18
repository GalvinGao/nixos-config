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
    })
  ];

  users.users.galvin = {
    name = "galvin";
    home = "/Users/galvin";
  };

}
