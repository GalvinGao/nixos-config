{ ... }:

{
  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    signing = {
      key = "CC0670FEA462E81E9E22DA85B364A85BFAFCF71A";
      signByDefault = true;
      signer = "/usr/local/bin/gpg";
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

      # Agent / tool scratch dirs
      ".playwright-mcp/"
      ".superpowers/"
    ];

    settings = {
      user.name = "GalvinGao";
      user.email = "me@galvingao.com";

      alias = {
        set-upstream = "!git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)";
        claude-miku = "CLAUDE_CONFIG_DIR=~/.claude-miku claude";
      };

      core.autocrlf = "input";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "current";
      rebase.autostash = true;
      rerere.enabled = true;
      remote.pushDefault = "origin";
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
