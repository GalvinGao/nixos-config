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
      "amplitude/ampli/ampli"

      "baidupcs-go"
      "cameroncooke/axe/axe"

      # Kubernetes & Container Tools
      "argoproj/tap/kubectl-argo-rollouts"
      "argoproj/tap/argocd"

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
      "beyond-compare" # File/folder diff and merge
      "copilot-for-xcode" # GitHub Copilot for Xcode
      "codex-app" # OpenAI Codex desktop app
      "cursor" # AI-first code editor
      "devcleaner" # Xcode cache cleaner
      "elasticvue" # Elasticsearch GUI client
      "ghostty" # Modern GPU-accelerated terminal
      "hoppscotch" # API development ecosystem
      "iterm2" # Terminal replacement
      "lens" # Kubernetes management IDE
      "opencode-desktop" # Open-source AI coding agent (desktop)
      "orbstack" # Fast Docker & Linux on macOS
      "postman" # API platform for building and testing
      "redis-insight" # Redis GUI client
      "swiftformat-for-xcode" # Swift code formatter
      "visual-studio-code" # VS Code stable build
      "visual-studio-code@insiders" # VS Code Insiders build
      "vscodium" # Community-driven VS Code
      "xcodes-app" # Xcode version manager
      "zed" # High-performance multiplayer editor

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
      "1password" # Password manager
      "1password-cli" # 1Password command-line interface
      "appcleaner" # Thorough app uninstaller
      "apparency" # App security inspector
      "coconutbattery" # Battery health monitor
      "dockdoor" # Dock window previews and switcher
      "gpg-suite" # Encryption and signing tools
      "gstreamer-runtime" # Multimedia framework
      "hex-fiend" # Hex editor
      "keka" # File compression tool
      "maccy" # Clipboard manager
      "maczip" # Archiver with encryption
      "macs-fan-control" # Manual fan control
      "medis" # Redis GUI client
      "notunes" # iTunes/Music auto-launch blocker
      "openmtp" # Android file transfer utility
      "raycast" # Productivity launcher
      "setapp" # Curated app subscription
      "snipaste" # Screenshot and annotation
      "squirrel-app" # Rime input method
      "stats" # System monitor menubar app
      "suspicious-package" # Installer inspector
      "yubico-authenticator" # YubiKey OTP/OATH client

      # Communication & Network Tools
      # Apps for communication, file transfer, and network analysis
      "anydesk" # Remote desktop
      "cloudflare-warp" # Cloudflare VPN / 1.1.1.1
      "cyberduck" # Cloud storage browser
      "discord" # Voice and text chat
      "lark" # Lark / Feishu workspace messenger
      "motrix" # Download manager
      "notion" # Notes, docs, wikis
      "qq" # Instant messaging
      "surge" # Advanced proxy / traffic tool
      "tailscale-app" # Zero-config mesh VPN
      "teamspeak-client@beta" # Voice chat client
      "telegram" # Messaging platform
      "tencent-meeting" # Video conferencing
      "transmission" # Torrent client
      "transmit" # SFTP/S3/cloud file transfer
      "vnc-viewer" # RealVNC client
      "wechat" # Messaging and social
      "whatsapp" # Messaging platform
      "wireshark-app" # Network protocol analyzer
      "slack" # Team communication and collaboration
      "zoom" # Video conferencing

      # Media & Design Tools
      # Creative tools for media management and design
      "figma" # Design and prototyping
      "moonlight" # Game streaming client
      "iina" # Modern media player
      "obs" # Open Broadcaster Software
      "screen-studio" # Screen recording with auto-zoom
      "sigil" # EPUB ebook editor
      "sonobus" # Audio streaming
      "steam" # Game distribution platform
      "vlc" # Cross-platform multimedia player
      "xnconvert" # Batch image processor

      # AI & LLM Tools
      "chatwise" # Multi-model AI chat client
      "claude" # Anthropic's official Claude desktop app
      "lm-studio" # Local LLM runner
      "ollama-app" # Local LLM runtime
      "superset" # Terminal for orchestrating agents
      "typeless" # AI voice dictation

      # Education & Publishing
      "basictex" # Minimal TeX distribution

      # QuickLook Extensions
      # Enhanced file preview plugins for macOS
      "qlcolorcode" # Source code with syntax highlighting
      "qlmarkdown" # Markdown files
      "qlstephen" # Plain text files
      "quicklook-video" # Video thumbnails and previews
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
      "playcover-community" # Run iOS apps on Apple Silicon
      "wine-stable" # Windows compatibility layer
      "zulu@17" # Certified OpenJDK distribution

      "codexbar" # Code snippet manager
      "gcloud-cli" # Google Cloud SDK
      "mongodb-compass"

      "productdevbook/tap/portkiller"
    ];
  };
}
