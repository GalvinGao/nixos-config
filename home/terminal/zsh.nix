{ ... }:

{
  programs.zsh = {
    enable = true;

    # Enable Oh My Zsh
    oh-my-zsh = {
      enable = true;
      theme = "edvardm";
      plugins = [
        "autojump"
        "doctl"
        "docker-compose"
        "fzf"
        "git"
        "gitignore"
        "macos"
        "pod"
        "tmux"
        "rust"
        "yarn"
      ];
    };

    # Enable syntax highlighting
    syntaxHighlighting.enable = true;

    # Enable autosuggestions
    autosuggestion = {
      enable = true;
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "nano";
      GPG_TTY = "$(tty)";
      COPYFILE_DISABLE = "true";
      HOMEBREW_NO_AUTO_UPDATE = "1";
      ANDROID_HOME = "/Users/$USER/Library/Android/sdk";
      VSCODE = "code-insiders";
      HISTFILE = "~/.zsh_history";
      HISTSIZE = "100000000";
      SAVEHIST = "100000000";
      BUN_INSTALL = "$HOME/.bun";
      PKG_CONFIG_PATH = "/opt/homebrew/Cellar/vips/8.16.0/lib/pkgconfig:$PKG_CONFIG_PATH";
    };

    # Aliases
    shellAliases = {
      rmq = "xattr -r -d com.apple.quarantine";
      chrome = "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome";
      "吃的" = "cd";
      kpg = "kubectl --kubeconfig='$HOME/.kube/penguin'";
      kmaa = "kubectl --kubeconfig='$HOME/.kube/maa'";
      k = "kubectl";
      androidemu = "nohup /Users/galvin/Library/Android/sdk/emulator/emulator @Main_Pixel_8_Pro_API_34 >/dev/null 2>&1";
      n = "npm";
      p = "pnpm";
      pua = "pnpm dlx shadcn@latest add";
      ls = "eza";
      ll = "eza --long --header --group --time-style long-iso";
      nr = "npm run";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };

    initContent = ''
      # Path additions
      export PATH="/opt/homebrew/Cellar/postgresql@16/16.6/bin:$HOME/.bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH:$HOME/go/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/Users/galvin/go/bin:/Users/galvin/Static/PATH:/Users/galvin/.cargo/bin:/Users/galvin/.local/bin/"
      export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"
      export PATH="$BUN_INSTALL/bin:$PATH"
      export PATH="/usr/local/clamav/bin:/usr/local/clamav/sbin:$PATH"

      # Functions
      function gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ }

      function gtp() {
        git tag $@
        git push origin $@
      }

      function gitbump() {
        VERSION=$(git describe --tags --abbrev=0 | awk -F. '{OFS="."; $NF+=1; print $0}')
        echo "Bumping version to -> $VERSION"
        read -q "REPLY?Are you sure? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push
            git tag -a -m "" "$VERSION"
            git push origin "$VERSION"
        fi
      }

      function listening() {
        if [ $# -eq 0 ]; then
            sudo lsof -iTCP -sTCP:LISTEN -n -P
        elif [ $# -eq 1 ]; then
            sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
        else
            echo "Usage: listening [pattern]"
        fi
      }

      function git-https() {
        git remote set-url origin https://github.com/$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
      }

      function git-ssh() {
        git remote set-url origin git@github.com:$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
      }

      # fnm
      eval "$(fnm env --use-on-cd)"

      # Completions
      autoload -U +X bashcompinit && bashcompinit
      complete -o nospace -C /opt/homebrew/bin/terraform terraform

      # Source additional configurations
      [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
      [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"
      [ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

      # Welcome message
      echo "Welcome :D"
    '';
  };
}
