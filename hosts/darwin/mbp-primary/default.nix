{ inputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./../../../core/mbp-darwin-core.nix
    ./../../../home/mbp-darwin-home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "galvin";
  system.stateVersion = 6;

  # Dock tiles — left-to-right order. Rewritten on every `make switch`,
  # so drag-reordering in the UI will not survive.
  system.defaults.dock.persistent-apps = [
    "/Applications/Claude.app"
    "/Applications/Google Chrome.app"
    "/Applications/Codex.app"
    "/System/Applications/Calendar.app"
    "/Applications/Setapp/Spark Mail.app"
    "/System/Applications/Music.app"
    "/Applications/WeChat.app"
    "/Applications/QQ.app"
    "/Applications/LarkSuite.app"
    "/Applications/Telegram.app"
    "/Applications/Discord.app"
    "/Applications/Notion.app"
    "/System/Applications/System Settings.app"
    "/Applications/Ghostty.app"
    "/Applications/Figma.app"
    "/Applications/Hoppscotch.app"
    "/Applications/Lens.app"
    "/Applications/Transmit.app"
    "/Applications/Setapp/TablePlus.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Xcode-26.4.1.app"
    "/System/Applications/iPhone Mirroring.app"
  ];
  system.defaults.dock.persistent-others = [
    { folder = { path = "/Users/galvin/Downloads"; arrangement = "date-modified"; }; }
  ];
}
