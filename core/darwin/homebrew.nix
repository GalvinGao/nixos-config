{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    brews = [
      # Network
      "cloudflared"
    ];
    casks = [
      # Development Tools
      "android-studio"
      "copilot-for-xcode"
      "devcleaner"  # Xcode cache cleaner
      "ghostty"     # GPU-accelerated terminal emulator
      "google-cloud-sdk"
      "hoppscotch"  # API development and testing platform
      "lens"        # Kubernetes IDE
      "orbstack"    # Docker/Linux containers and machines
      "postman"
      "redis-insight"
      "swiftformat-for-xcode"
      "visual-studio-code@insiders"
      "vscodium"    # Open source VS Code build
      "xcodes"      # Xcode versions manager

      # Browsers
      "chromium"
      "firefox"
      "google-chrome"
      "google-chrome@dev"

      # System Utilities
      "1password-cli"
      "appcleaner"
      "apparency"   # Mac app security inspector
      "coconutbattery"
      "gpg-suite"
      "gstreamer-runtime"
      "keka"        # File archiver
      "mac-mouse-fix"
      "maccy"       # Clipboard manager
      "maczip"
      "medis"       # Redis GUI client
      "notunes"     # Prevents iTunes/Music from launching
      "openmtp"     # Android file transfer
      "raycast"     # Spotlight replacement
      "snipaste"    # Screenshot and annotation tool
      "stats"       # MenuBar system monitor
      "suspicious-package" # Installer package inspector

      # Network & Communication
      "cyberduck"   # FTP/Cloud storage browser
      "discord"
      "openvpn-connect"
      "qq"
      "teamspeak-client@beta"
      "telegram"
      "transmission"
      "wechat"
      "whatsapp"
      "wireshark"

      # Media & Creative
      "calibre"
      "figma"
      "iina"        # Modern media player
      "inkscape"
      "losslesscut" # Media trimmer
      "sigil"       # EPUB editor
      "sonobus"     # Audio streaming
      "xnconvert"   # Batch image processor

      # QuickLook Plugins
      "qlcolorcode" # Syntax highlighting in QuickLook
      "qlmarkdown"  # Markdown QuickLook preview
      "qlstephen"   # Plain text QuickLook preview
      "qlvideo"     # Video thumbnail QuickLook
      "quicklook-json" # JSON QuickLook preview
      "quicklookase" # Adobe ASE color palette preview

      # Fonts
      "font-cascadia-code"
      "font-cascadia-mono"
      "font-caskaydia-cove-nerd-font"
      "font-fira-code"
      "font-geist-mono-nerd-font"
      "font-intel-one-mono"
      "font-inter"
      "font-jetbrains-mono-nerd-font"
      "font-maple-mono-nf-cn"

      # Other
      "wine-stable" # Run Windows apps on macOS
      "zulu@17"     # OpenJDK distribution
    ];
  };
}