{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = [
      "amplitude/ampli"
      "hashicorp/tap"
      "siderolabs/tap"
      "tw93/tap" # for mole
    ];

    brews = [
      # Network & Infrastructure
      "cloudflared"
      "hashicorp/tap/consul"
      "siderolabs/tap/talosctl"
      "awscli"
      "s5cmd"
      "ffmpeg"
      "axel"
      "qshell"

      "redis"
      "mysql"
      "postgresql@16"
      "postgresql@17"
      "postgresql@18"
      "nats-server"
      "cocoapods"
      "ampli"

      "baidupcs-go"
      "pkgconfig"
      "httpie"

      "arp-scan"
      "asciinema"
      "ast-grep"
      "bundletool"
      "ios-deploy"
      "kubectl-argo-rollouts"
      "maestro"
      "miniserve"
      "tw93/tap/mole"
      "mongosh"
      "nx"
      "opencode"
      "parallel"
      "pigz"
      "python@3.13"
      "telnet"
      "watch"

      # Dependencies that can't be auto-removed
      "act"
      "doge"
      "node@18" # required by ampli
      "postgresql@14"
      "pv"
    ];

    casks = [
      # Development Environments & IDEs
      # Full-featured development environments and code editors
      "android-studio" # Android development IDE
      "copilot-for-xcode" # GitHub Copilot for Xcode
      "devcleaner" # Xcode cache cleaner
      "ghostty" # Modern GPU-accelerated terminal
      "hoppscotch" # API development ecosystem
      "lens" # Kubernetes management IDE
      "orbstack" # Fast Docker & Linux on macOS
      "postman" # API platform for building and testing
      "redis-insight" # Redis GUI client
      "swiftformat-for-xcode" # Swift code formatter
      "visual-studio-code@insiders" # VS Code Insiders build
      "vscodium" # Community-driven VS Code
      "xcodes-app" # Xcode version manager

      # Web Browsers & Development
      # Web browsers and development tools
      "chromium" # Open source browser
      "firefox" # Mozilla web browser
      "google-chrome" # Chrome stable
      "google-chrome@dev" # Chrome development channel

      # System & Security Tools
      # System utilities, security, and productivity enhancements
      "appcleaner" # Thorough app uninstaller
      "apparency" # App security inspector
      "coconutbattery" # Battery health monitor
      "gpg-suite" # Encryption and signing tools
      "gstreamer-runtime" # Multimedia framework
      "keka" # File compression tool
      "mac-mouse-fix" # Mouse/trackpad customization
      "maccy" # Clipboard manager
      "maczip" # Archiver with encryption
      "medis" # Redis GUI client
      "notunes" # iTunes/Music auto-launch blocker
      "openmtp" # Android file transfer utility
      "raycast" # Productivity launcher
      "snipaste" # Screenshot and annotation
      "stats" # System monitor menubar app
      "suspicious-package" # Installer inspector

      # Communication & Network Tools
      # Apps for communication, file transfer, and network analysis
      "cyberduck" # Cloud storage browser
      "discord" # Voice and text chat
      "openvpn-connect" # VPN client
      "qq" # Instant messaging
      "teamspeak-client@beta" # Voice chat client
      "telegram" # Messaging platform
      "transmission" # Torrent client
      "wechat" # Messaging and social
      "whatsapp" # Messaging platform
      "wireshark-app" # Network protocol analyzer

      # Media & Design Tools
      # Creative tools for media management and design
      "figma" # Design and prototyping
      "moonlight" # Game streaming client
      "iina" # Modern media player
      "obs" # Open Broadcaster Software
      "sigil" # EPUB ebook editor
      "sonobus" # Audio streaming
      "vlc" # Cross-platform multimedia player
      "xnconvert" # Batch image processor

      # QuickLook Extensions
      # Enhanced file preview plugins for macOS
      "qlcolorcode" # Source code with syntax highlighting
      "qlmarkdown" # Markdown files
      "qlstephen" # Plain text files
      "qlvideo" # Video thumbnails
      "quicklook-json" # JSON files
      "quicklookase" # Adobe Swatch Exchange files

      # Development Fonts
      # Programming and development optimized fonts
      "font-cascadia-code" # Microsoft's monospace font
      "font-cascadia-mono" # Cascadia without ligatures
      "font-caskaydia-cove-nerd-font" # Nerd Font variant
      "font-fira-code" # Monospace with ligatures
      "font-geist-mono-nerd-font" # Vercel's monospace font
      "font-intel-one-mono" # Intel's monospace font
      "font-inter" # UI typeface
      "font-jetbrains-mono-nerd-font" # IDE-optimized font
      "font-maple-mono-nf-cn" # CJK-compatible monospace

      # Platform Compatibility
      # Tools for cross-platform compatibility
      "wine-stable" # Windows compatibility layer
      "zulu@17" # Certified OpenJDK distribution

      "gcloud-cli"
      "mongodb-compass"
    ];
  };
}
