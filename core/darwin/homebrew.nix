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
      "argoproj/tap"
      "cameroncooke/axe"
      "siderolabs/tap"
      "tw93/tap" # for mole
      "productdevbook/tap" # for portkiller
      "steipete/tap" # for codexbar
    ];

    brews = [
      # Network & Infrastructure (Homebrew-only)
      "siderolabs/tap/talosctl"
      "qshell"

      # Databases (keep in Homebrew — brew services for daemon management)
      "redis"
      "mysql"
      "postgresql@14"
      "postgresql@16"
      "postgresql@17"
      "postgresql@18"
      "nats-server"

      "cocoapods"
      "ampli"

      "baidupcs-go"
      "cameroncooke/axe/axe"

      # Kubernetes & Container Tools
      "kubectl-argo-rollouts"
      "argocd"

      "tw93/tap/mole"
      "nx"

      # Dependencies that can't be auto-removed
      "doge"
      "node@18" # required by ampli

      "dotnet@9"
    ];

    casks = [
      # Development Environments & IDEs
      # Full-featured development environments and code editors
      "android-studio" # Android development IDE
      "copilot-for-xcode" # GitHub Copilot for Xcode
      "codex-app" # OpenAI Codex desktop app
      "devcleaner" # Xcode cache cleaner
      "ghostty" # Modern GPU-accelerated terminal
      "hoppscotch" # API development ecosystem
      "lens" # Kubernetes management IDE
      "orbstack" # Fast Docker & Linux on macOS
      "postman" # API platform for building and testing
      "redis-insight" # Redis GUI client
      "swiftformat-for-xcode" # Swift code formatter
      "visual-studio-code" # VS Code stable build
      "visual-studio-code@insiders" # VS Code Insiders build
      "vscodium" # Community-driven VS Code
      "xcodes-app" # Xcode version manager

      # Web Browsers & Development
      # Web browsers and development tools
      "chromium" # Open source browser
      "firefox" # Mozilla web browser
      "google-chrome" # Chrome stable
      "google-chrome@dev" # Chrome development channel

      # Backup
      "backblaze" # Cloud backup service

      # System & Security Tools
      # System utilities, security, and productivity enhancements
      "appcleaner" # Thorough app uninstaller
      "apparency" # App security inspector
      "coconutbattery" # Battery health monitor
      "dockdoor" # Dock window previews and switcher
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
      "slack" # Team communication and collaboration

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

      # Education & Publishing
      "basictex" # Minimal TeX distribution

      # QuickLook Extensions
      # Enhanced file preview plugins for macOS
      "qlcolorcode" # Source code with syntax highlighting
      "qlmarkdown" # Markdown files
      "qlstephen" # Plain text files
      "quicklook-video" # Video thumbnails and previews
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

      "codexbar" # Code snippet manager
      "gcloud-cli" # Google Cloud SDK
      "mongodb-compass"

      "productdevbook/tap/portkiller"
    ];
  };
}
