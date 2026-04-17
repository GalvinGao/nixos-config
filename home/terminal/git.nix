{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    difftastic.enable = true;

    userName = "GalvinGao";
    userEmail = "me@galvingao.com";

    signing = {
      key = "CC0670FEA462E81E9E22DA85B364A85BFAFCF71A";
      signByDefault = true;
      gpgPath = "/usr/local/bin/gpg";
    };

    aliases = {
      set-upstream = "!git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)";
    };

    # Written to ~/.config/git/ignore; git reads XDG path automatically.
    ignores = [
      # Node
      "npm-debug.log"

      # Mac
      ".DS_Store"

      # Windows
      "Thumbs.db"

      # JetBrains
      ".idea/"

      # vi
      "*~"

      # General
      "log/"
      "*.log"

      ".history/"
      ".vscode/*"
      "!.vscode/extensions.json"

      # Local-only config files
      ".superset/config.json"
      ".claude/settings.local.json"
      ".mcp.json"
    ];

    extraConfig = {
      core.autocrlf = "input";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "current";
      rebase.autostash = true;
      http.cookiefile = "/Users/galvin/.gitcookies";
      gc.reflogExpire = 360;
      protocol.version = 2;
      credential = {
        "https://github.com" = {
          helper = [
            ""
            "!/etc/profiles/per-user/galvin/bin/gh auth git-credential"
          ];
        };
        "https://gist.github.com" = {
          helper = [
            ""
            "!/etc/profiles/per-user/galvin/bin/gh auth git-credential"
          ];
        };
      };
    };
  };
}
