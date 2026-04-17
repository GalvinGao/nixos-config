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

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

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
    trackpad.Dragging = false;
    trackpad.TrackpadRightClick = true;
    trackpad.TrackpadThreeFingerDrag = false;
    trackpad.FirstClickThreshold = 0;
    trackpad.SecondClickThreshold = 0;
    NSGlobalDomain."com.apple.trackpad.scaling" = 0.875;
    NSGlobalDomain."com.apple.trackpad.forceClick" = true;

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

  nix.gc.automatic = true;
  nix.gc.interval.Hour = 3;
  nix.gc.options = "--delete-older-than 15d";
  nix.optimise.automatic = true;
  nix.optimise.interval.Hour = 4;
}
