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
    autosuggestion.enable = true;

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
      DOTNET_ROOT = "/opt/homebrew/opt/dotnet@9/libexec";
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
      ll = "eza --long --header --group --time-style long-iso -la";
      nr = "npm run";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      ecr_dive = "sh /Users/galvin/Static/ecr_inspect.sh";
      yolo = "claude --dangerously-skip-permissions";
    };

    initContent = ''
      # Path additions
      export PATH="/opt/homebrew/opt/dotnet@9/bin:/opt/homebrew/Cellar/postgresql@16/16.6/bin:$HOME/.bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH:$HOME/go/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/Users/galvin/go/bin:/Users/galvin/Static/PATH:/Users/galvin/.cargo/bin:/Users/galvin/.local/bin/"
      export PATH="$BUN_INSTALL/bin:$PATH"
      export PATH="/usr/local/clamav/bin:/usr/local/clamav/sbin:$PATH"
      export PATH="/Users/galvin/.local/share/fnm/node-versions/v25.6.1/installation/bin:$PATH"

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

      # clone <git-url> [extra git-clone flags]
      # Parses the URL, rejects hosts other than github.com / gitlab.com,
      # and clones via SSH into ~/Projects/<org>/<repo>.
      function clone() {
        if [ $# -lt 1 ]; then
          echo "Usage: clone <git-url> [git-clone-flags...]" >&2
          return 1
        fi

        local url="$1"
        shift
        url="''${url%.git}"
        url="''${url%/}"

        # NB: can't name this local `path` — zsh ties it to $PATH and would
        # blank out command lookup inside this function.
        local host repo_path
        if [[ "$url" =~ '^(https?://|git@)?([^:/]+)[:/](.+)$' ]]; then
          host="''${match[2]}"
          repo_path="''${match[3]}"
        else
          echo "clone: unrecognized URL: $url" >&2
          return 1
        fi

        case "$host" in
          github.com|gitlab.com) ;;
          *)
            echo "clone: unsupported host '$host' (only github.com and gitlab.com)" >&2
            return 1
            ;;
        esac

        local org="''${repo_path%%/*}"
        local repo="''${repo_path#*/}"
        if [ "$org" = "$repo_path" ] || [ -z "$repo" ]; then
          echo "clone: URL must include both organization and repository: $url" >&2
          return 1
        fi

        # Rewrite org for the local filesystem path; remote URL still uses
        # the real org name.
        local local_org="$org"
        case "$org" in
          troph-team) local_org=troph ;;
        esac
        local dest="$HOME/repo/$local_org/$repo"
        mkdir -p "$(dirname "$dest")"
        git clone "$@" "git@''${host}:''${org}/''${repo}.git" "$dest"
      }

      # clone-org <org> [--max-size-mb N] [--parallel N]
      # Pulls the 300 most recently updated repos in <org> via `gh`, skips any
      # larger than the limit (default 300 MB), and clones the rest with `clone`
      # (default 8 in parallel).
      function clone-org() {
        local max_size_mb=300
        local parallel=8
        local org=""
        while [ $# -gt 0 ]; do
          case "$1" in
            -m|--max-size-mb)
              max_size_mb="$2"
              shift 2
              ;;
            --max-size-mb=*)
              max_size_mb="''${1#*=}"
              shift
              ;;
            -p|--parallel)
              parallel="$2"
              shift 2
              ;;
            --parallel=*)
              parallel="''${1#*=}"
              shift
              ;;
            -h|--help)
              echo "Usage: clone-org <org> [--max-size-mb N] [--parallel N]"
              return 0
              ;;
            -*)
              echo "clone-org: unknown flag: $1" >&2
              return 1
              ;;
            *)
              if [ -z "$org" ]; then
                org="$1"
              else
                echo "clone-org: unexpected positional arg: $1" >&2
                return 1
              fi
              shift
              ;;
          esac
        done

        if [ -z "$org" ]; then
          echo "Usage: clone-org <org> [--max-size-mb N] [--parallel N]" >&2
          return 1
        fi

        local max_kb=$(( max_size_mb * 1024 ))
        local running=0
        local name_with_owner disk_kb mb

        while IFS=$'\t' read -r name_with_owner disk_kb; do
          if [ "$disk_kb" -gt "$max_kb" ]; then
            mb=$(( disk_kb / 1024 ))
            echo "[skip] $name_with_owner: ''${mb}MB exceeds ''${max_size_mb}MB limit"
            continue
          fi
          echo "[clone] $name_with_owner (''${disk_kb}KB)"
          clone "git@github.com:''${name_with_owner}.git" &
          running=$(( running + 1 ))
          if (( running >= parallel )); then
            wait -n
            running=$(( running - 1 ))
          fi
        done < <(gh repo list "$org" --limit 300 --json nameWithOwner,diskUsage \
                 | jq -r '.[] | "\(.nameWithOwner)\t\(.diskUsage)"')

        wait
      }

      # fnm
      eval "$(fnm env --use-on-cd --shell zsh --version-file-strategy=recursive --corepack-enabled)"

      # Completions
      autoload -U +X bashcompinit && bashcompinit
      complete -o nospace -C /opt/homebrew/bin/terraform terraform

      # Source additional configurations
      [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
      [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"
      [ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

      eval "$(proto activate)"
    '';
  };
}
