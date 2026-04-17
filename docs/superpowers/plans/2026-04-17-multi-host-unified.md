# Multi-Host Unified Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure this nix-darwin flake to serve two Darwin hosts (`Galvin-MacBook-Pro`, `Galvin-MacBook-Pro-2024`) through a data-driven flake and thin host shells, ready to absorb NixOS hosts in the future.

**Architecture:** `flake.nix` iterates host-system data from `os/*.nix` through a shared `mkConfiguration` helper. Per-host thin shells in `hosts/darwin/<role>/` hold only host identity; the shared Darwin workstation profile lives in `core/mbp-darwin-core.nix` (system) + `home/mbp-darwin-home.nix` (home-manager). No custom options module, no match helper — deferred until variation justifies them.

**Tech Stack:** Nix flakes, nix-darwin, home-manager. Validation via `nix flake check`, `darwin-rebuild build`, and `make switch`.

**Design spec:** `docs/superpowers/specs/2026-04-17-multi-host-unified-design.md`.

**Preconditions:**
- Run on a feature branch (`git checkout -b refactor/multi-host-unified`) — do not commit directly to `main` until the plan completes.
- The current live generation is 114 (set by `Galvin-MacBook-Pro-2024`, the machine this plan runs on). Generation rollback works as a safety net: `sudo darwin-rebuild --rollback`.
- The uncommitted `README.md` in the working tree is expected; Task 7 rewrites it anyway.

---

## File Structure

New files this plan creates:

| Path | Responsibility |
|---|---|
| `os/darwin.nix` | Data list of Darwin system groups: `{ system, hosts, moduleResolver }`. |
| `core/mbp-darwin-core.nix` | Shared "Darwin workstation" system module: imports `core/darwin/`, `allowUnfree`, overlays, `system.defaults`, `environment.systemPackages`, `users.users.galvin`, nix GC/optimise. |
| `home/mbp-darwin-home.nix` | Shared "Darwin workstation" home-manager module: wires `home-manager = { … }`, imports `home/terminal/*`, declares `home.packages`, activation scripts, `programs.fzf`, `programs.bat`. |
| `hosts/darwin/mbp-primary/default.nix` | Thin shell for `Galvin-MacBook-Pro`. Sets `nixpkgs.hostPlatform`, `system.primaryUser`, `system.stateVersion`; imports core + home bundles. |
| `hosts/darwin/mbp-2024/default.nix` | Thin shell for `Galvin-MacBook-Pro-2024`. Byte-identical to `mbp-primary` today. |

Files this plan modifies:

| Path | Change |
|---|---|
| `flake.nix` | Replace per-host literal with `mkConfiguration` that iterates `os/*.nix`. |
| `detect-drift.sh` | Three line edits (see Task 5). |
| `README.md` | Rewrite "Repository layout", "Where to add new things", and "Adapting for your Mac" sections. Capture the 5 durable design decisions. |
| `AGENTS.md` | Rewrite "Repository Structure", "Where Packages Live", and "Editing Guidelines" sections with new paths + design decisions. |

Files this plan deletes:

| Path | Reason |
|---|---|
| `hosts/mbp-darwin/default.nix` | Content moved to `core/mbp-darwin-core.nix` + `home/mbp-darwin-home.nix` + `hosts/darwin/mbp-*/default.nix`. |
| `hosts/mbp-darwin/` (empty dir) | Superseded by `hosts/darwin/mbp-*/`. |

Files this plan leaves unchanged:

- `core/darwin/{default,homebrew,pam,backblaze}.nix`, `core/darwin/bzexcluderules_editable.xml`
- `home/terminal/{zsh,starship,atuin}.nix`
- `Makefile`, `flake.lock`, `print-missing-brew.sh`
- `.editorconfig`, `.vscode/`, `scripts/`

---

## Task 1 — Establish baseline

**Files:**
- Read: `flake.nix`, `hosts/mbp-darwin/default.nix`

- [ ] **Step 1.1: Create working branch**

```sh
cd /etc/nix-darwin
git checkout -b refactor/multi-host-unified
```

- [ ] **Step 1.2: Capture the current system derivation path**

Run:
```sh
nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system
```

Expected: prints a `/nix/store/<hash>-darwin-system-26.05.<rev>` path. Save this string — later tasks compare against it to verify the refactor produces an identical build.

```sh
BASELINE_PATH=$(nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system)
echo "$BASELINE_PATH" > /tmp/nix-darwin-baseline.txt
cat /tmp/nix-darwin-baseline.txt
```

- [ ] **Step 1.3: Verify `nix flake check` passes**

Run:
```sh
nix flake check --no-build
```

Expected: no errors. (It's fine if this is slow or pulls from cache.)

- [ ] **Step 1.4: No commit — baseline is a reference, not a change**

---

## Task 2 — Extract `home/mbp-darwin-home.nix`

**Files:**
- Create: `home/mbp-darwin-home.nix`
- Modify: `hosts/mbp-darwin/default.nix` (temporary transitional state)

The current `hosts/mbp-darwin/default.nix:101-250` declares `home-manager = { useGlobalPkgs = true; useUserPackages = true; extraSpecialArgs = { inherit inputs; }; users.galvin = { … }; };`. Move this block into its own module. The host file continues to work because modules compose.

- [ ] **Step 2.1: Create `home/mbp-darwin-home.nix` with the home-manager block**

Create `home/mbp-darwin-home.nix`:

```nix
{ inputs, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.galvin = {
      imports = [
        ./terminal/zsh.nix
        ./terminal/starship.nix
        ./terminal/atuin.nix
      ];

      home.username = "galvin";
      home.homeDirectory = "/Users/galvin";
      home.stateVersion = "25.05";

      home.activation.installClaudeCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'export PATH="${pkgs.curl}/bin:/usr/bin:$PATH"; curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash'
      '';

      home.activation.installCodexCli = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash -c 'eval "$(${pkgs.fnm}/bin/fnm env --shell bash)"; npm i -g @openai/codex'
      '';

      programs.home-manager.enable = true;
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batgrep
        ];
      };

      home.packages = with pkgs; [
        yazi
        just
        pixman
        p7zip # 7-Zip file archiver

        nil
        nixfmt
        nh

        autojump
        starship

        xxHash
        grpc
        stripe-cli
        maestro
        openfga
        supabase-cli

        # Development
        openjdk
        apktool
        # argocd  # Build fails due to missing git in build sandbox - use Homebrew if needed
        aria2
        cmake
        dive
        doctl
        duckdb
        erlang
        exiftool
        fastfetch
        eza
        fastlane
        fnm
        git
        git-lfs
        gh # GitHub CLI
        go
        grafana
        grpcurl
        hashcat
        htop
        imagemagick
        iperf
        iperf3
        jq
        k6
        jmeter
        kubectl
        mtr
        ouch
        pandoc
        pngquant
        rclone
        rabbitmq-server
        speedtest-cli
        tmux
        tree
        wget
        yq
        yt-dlp

        # Migrated from Homebrew
        cloudflared
        consul
        awscli2
        s5cmd
        ffmpeg
        axel
        pkg-config
        httpie
        arp-scan
        asciinema
        ast-grep
        miniserve
        parallel
        pigz
        python313
        inetutils # includes telnet
        watch
        act
        pv

        proto

        # Identified from shell history (not previously declared)
        neovim
        mosh
        natscli # NATS CLI client (nats-server is in homebrew)
        wrk # HTTP benchmarking
        flyctl # Fly.io CLI
        binwalk

        # Migrated from Homebrew brews
        nmap
        kubernetes-helm # brew: helm (nix `helm` is a music synthesizer)
        kubectx
        kubeseal
        zellij
        brotli
        xcbeautify
        bundletool
        ios-deploy
        mongosh
        swiftlint
        swiftformat
        wakatime-cli
        vgmstream
        opencode
        prek
      ];
    };
  };
}
```

- [ ] **Step 2.2: Remove the home-manager block from `hosts/mbp-darwin/default.nix`**

Open `hosts/mbp-darwin/default.nix`. Delete the entire `home-manager = { … };` block (currently lines 101-250). Also delete the `inputs.home-manager.darwinModules.home-manager` entry from the `imports = [ … ]` list (line 9 today) — the new `home/mbp-darwin-home.nix` needs home-manager's darwin module to be imported. Add the new file to imports instead.

After this step, the top of `hosts/mbp-darwin/default.nix` looks like:

```nix
{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./../../core/darwin
    ./../../home/mbp-darwin-home.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    nano

    terminal-notifier
  ];
  # … rest unchanged (system settings, system.defaults, overlays, users.users.galvin, nix.gc, nix.optimise)
}
```

- [ ] **Step 2.3: Verify the transitional build produces the baseline derivation**

Run:
```sh
NEW_PATH=$(nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system)
BASELINE_PATH=$(cat /tmp/nix-darwin-baseline.txt)
echo "baseline: $BASELINE_PATH"
echo "new:      $NEW_PATH"
[ "$NEW_PATH" = "$BASELINE_PATH" ] && echo "OK: identical" || echo "DIFF: not identical"
```

Expected: "OK: identical". The refactor at this stage is a pure move — derivation hash must match.

If it differs, diff the two outputs:
```sh
nix store diff-closures "$BASELINE_PATH" "$NEW_PATH"
```
And investigate before proceeding. Likely cause: a typo, missing import, or a stray attribute re-ordering that triggered a rebuild.

- [ ] **Step 2.4: Commit**

```sh
git add home/mbp-darwin-home.nix hosts/mbp-darwin/default.nix
git commit -m "refactor: extract home-manager config to home/mbp-darwin-home.nix"
```

---

## Task 3 — Extract `core/mbp-darwin-core.nix`

**Files:**
- Create: `core/mbp-darwin-core.nix`
- Modify: `hosts/mbp-darwin/default.nix` (further reduced — will be deleted in Task 4)

- [ ] **Step 3.1: Create `core/mbp-darwin-core.nix`**

Create `core/mbp-darwin-core.nix`:

```nix
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
    NSGlobalDomain."com.apple.trackpad.scaling" = 0.875;

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
```

Note what did **not** move:
- `system.stateVersion = 6;` → stays in the thin host shell (next task).
- `system.primaryUser = "galvin";` → stays in the thin host shell.
- `nixpkgs.hostPlatform` → set in the thin host shell.

- [ ] **Step 3.2: Reduce `hosts/mbp-darwin/default.nix` to import-only + host identity**

Replace the contents of `hosts/mbp-darwin/default.nix` with:

```nix
{ inputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./../../core/mbp-darwin-core.nix
    ./../../home/mbp-darwin-home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "galvin";
  system.stateVersion = 6;
}
```

This file is now 13 lines and is a functional equivalent of the old one — it's the transitional bridge until the flake entry point switches (Task 4).

- [ ] **Step 3.3: Verify the transitional build produces the baseline closure**

The success criterion for this task is **runtime closure package-set equality**, not hash equality. When `environment.systemPackages` moves from a root module into an imported module, the nix module system merges the list in a different order. That changes the `pkgs` arg to `buildEnv`, cascading into new hashes for `system-path`, `etc`, `system-applications`, and the top-level `darwin-system-*` — with no semantic change to what's installed.

Run:
```sh
NEW_PATH=$(nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system)
BASELINE_PATH=$(cat /tmp/nix-darwin-baseline.txt)
diff <(nix-store -q --requisites "$BASELINE_PATH" | sort) <(nix-store -q --requisites "$NEW_PATH" | sort)
```

Expected: the only differences are at most 4 hash-cascade artifacts — `darwin-system-*`, `system-path`, `etc`, `system-applications`. Every other store path (every installed package) must be identical.

If any actual package path differs, STOP — something semantic changed. Run `nix store diff-closures "$BASELINE_PATH" "$NEW_PATH"` to see which package changed, investigate, and report back as DONE_WITH_CONCERNS or BLOCKED without committing.

- [ ] **Step 3.4: Commit**

```sh
git add core/mbp-darwin-core.nix hosts/mbp-darwin/default.nix
git commit -m "refactor: extract core system config to core/mbp-darwin-core.nix"
```

---

## Task 4 — Add data-driven flake + thin host shells; swap entry point

**Files:**
- Create: `os/darwin.nix`, `hosts/darwin/mbp-primary/default.nix`, `hosts/darwin/mbp-2024/default.nix`
- Modify: `flake.nix`
- Delete: `hosts/mbp-darwin/default.nix`, empty `hosts/mbp-darwin/` directory

- [ ] **Step 4.1: Create `os/darwin.nix`**

Create `os/darwin.nix`:

```nix
[
  {
    system = "aarch64-darwin";
    hosts = [
      "Galvin-MacBook-Pro"
      "Galvin-MacBook-Pro-2024"
    ];
    moduleResolver = host: [
      (
        ./.. + "/hosts/darwin/" + (
          if host == "Galvin-MacBook-Pro" then "mbp-primary"
          else if host == "Galvin-MacBook-Pro-2024" then "mbp-2024"
          else throw "os/darwin.nix: no mapping for host '${host}'"
        )
      )
    ];
  }
]
```

The explicit `throw` surfaces a useful error if someone adds a host to the list but forgets to create a directory.

- [ ] **Step 4.2: Create `hosts/darwin/mbp-primary/default.nix`**

Create `hosts/darwin/mbp-primary/default.nix`:

```nix
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
}
```

- [ ] **Step 4.3: Create `hosts/darwin/mbp-2024/default.nix`**

Create `hosts/darwin/mbp-2024/default.nix` with **the same content** as `mbp-primary/default.nix`:

```nix
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
}
```

The two files are byte-identical today. This is intentional: divergence, if it ever happens, goes here.

- [ ] **Step 4.4: Rewrite `flake.nix`**

Replace the entire contents of `flake.nix` with:

```nix
{
  description = "Galvin's nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    _1password-shell-plugins.url = "github:1Password/shell-plugins";
  };

  outputs =
    {
      nix-darwin,
      nixpkgs,
      ...
    }@inputs:
    let
      darwinSystems = import ./os/darwin.nix;

      mkConfiguration =
        { systems, mkSystem }:
        builtins.listToAttrs (
          builtins.concatMap (
            sys:
            builtins.map (host: {
              name = host;
              value = mkSystem {
                system = sys.system;
                specialArgs = { inherit inputs; };
                modules = sys.moduleResolver host;
              };
            }) sys.hosts
          ) systems
        );
    in
    {
      darwinConfigurations = mkConfiguration {
        systems = darwinSystems;
        mkSystem = nix-darwin.lib.darwinSystem;
      };

      homeManagerModules = {
        _1password-shell-plugins = inputs._1password-shell-plugins.hmModules.default;
      };
    };
}
```

Note: `homeManagerModules._1password-shell-plugins` is preserved — it was an output of the old flake.

- [ ] **Step 4.5: Delete the old host file and empty directory**

```sh
git rm hosts/mbp-darwin/default.nix
# Remove the now-empty directory (if any tracked content remains, inspect first)
rmdir hosts/mbp-darwin
```

- [ ] **Step 4.6: Build both Darwin configurations and verify closure parity**

```sh
PRIMARY_PATH=$(nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro.system)
LEGACY_PATH=$(nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system)
BASELINE_PATH=$(cat /tmp/nix-darwin-baseline.txt)
echo "baseline: $BASELINE_PATH"
echo "primary:  $PRIMARY_PATH"
echo "2024:     $LEGACY_PATH"

# The two hosts should produce IDENTICAL derivations — their thin shells
# and shared modules are byte-identical, so this is an exact hash match.
[ "$PRIMARY_PATH" = "$LEGACY_PATH" ] && echo "OK: mbp-primary and mbp-2024 produce identical derivations" || echo "DIFF: the two hosts differ — investigate"

# Compare the 2024 build's runtime closure to the baseline. Hash-cascade
# artifacts (darwin-system-*, system-path, etc, system-applications) may
# differ without being a problem; every other store path must be identical.
diff <(nix-store -q --requisites "$BASELINE_PATH" | sort) <(nix-store -q --requisites "$LEGACY_PATH" | sort)
```

Expected:
- `OK: mbp-primary and mbp-2024 produce identical derivations` — both hosts share the same thin-shell content and bundles.
- The `diff` output contains **only** the four hash-cascade artifact differences (`darwin-system-*`, `system-path`, `etc`, `system-applications`). Every actual package path must match the baseline.

If an actual package differs, `nix store diff-closures "$BASELINE_PATH" "$LEGACY_PATH"` to investigate. Common causes: typo in `moduleResolver`, wrong relative path in a thin shell, forgotten import.

- [ ] **Step 4.7: Run `nix flake check`**

```sh
nix flake check --no-build
```

Expected: no errors.

- [ ] **Step 4.8: Activate the new config on the live host**

```sh
sudo nh darwin switch .
```

Expected:
- Build succeeds (content should be cached from Step 4.6).
- Activation completes. A new generation is created.
- The `Refusing to untap steipete/tap` error from earlier activations does not reappear (the tap is now declared).

Verify the new generation:
```sh
sudo darwin-rebuild --list-generations | tail -3
```

Expected: a new generation (115 or higher) timestamped "now" and marked `(current)`.

- [ ] **Step 4.9: Commit**

```sh
git add os/darwin.nix hosts/darwin/mbp-primary/default.nix hosts/darwin/mbp-2024/default.nix flake.nix
git add -u   # picks up deletions
git commit -m "refactor: data-driven flake with per-host thin shells

Introduce os/darwin.nix as a data list of host systems; flake.nix
iterates via mkConfiguration. Per-host thin shells in hosts/darwin/
import core/mbp-darwin-core.nix + home/mbp-darwin-home.nix. Both
Darwin hosts produce identical derivations today; divergence room
lives in the thin shells."
```

---

## Task 5 — Patch `detect-drift.sh`

**Files:**
- Modify: `detect-drift.sh:7`, `detect-drift.sh:129`, `detect-drift.sh:681`

- [ ] **Step 5.1: Repoint `HOST_NIX` to the home bundle**

In `detect-drift.sh` line 7, change:
```sh
HOST_NIX="$REPO_DIR/hosts/mbp-darwin/default.nix"
```
to:
```sh
HOST_NIX="$REPO_DIR/home/mbp-darwin-home.nix"
```

Rationale: `HOST_NIX` is consumed once, at line 262 (`sed -n '/home\.packages = with pkgs;/,/\];/p' "$HOST_NIX"`), to extract the declared home-manager package list. After the refactor, `home.packages` lives in the home bundle.

- [ ] **Step 5.2: Make the display string host-agnostic**

In `detect-drift.sh` line 129, change:
```sh
echo "  Galvin-MacBook-Pro  •  $(date +%Y-%m-%d)"
```
to:
```sh
echo "  $(scutil --get LocalHostName 2>/dev/null || echo 'nix-darwin')  •  $(date +%Y-%m-%d)"
```

Rationale: the script now runs on either Mac; hardcoding one hostname is misleading.

- [ ] **Step 5.3: Update the guidance-message path**

In `detect-drift.sh` line 681, change:
```sh
echo -e "  ${DIM}Add to hosts/mbp-darwin/default.nix under system.defaults:${NC}"
```
to:
```sh
echo -e "  ${DIM}Add to core/mbp-darwin-core.nix under system.defaults:${NC}"
```

- [ ] **Step 5.4: Run the script and confirm no path errors**

```sh
./detect-drift.sh | head -40
```

Expected: script runs to completion. The banner shows the current machine's LocalHostName. Any `HOMEBREW_NIX`/`HOST_NIX` file reads succeed.

- [ ] **Step 5.5: Commit**

```sh
git add detect-drift.sh
git commit -m "chore: retarget detect-drift.sh paths for new layout

HOST_NIX now points at home/mbp-darwin-home.nix (source of truth for
home.packages). Banner reads LocalHostName instead of a hardcoded
hostname. Guidance message points at core/mbp-darwin-core.nix."
```

---

## Task 6 — Rewrite `README.md`

**Files:**
- Modify: `README.md`

Rewrite in full — the current file still references the pre-refactor layout, plus the uncommitted version is inconsistent with the refactor.

- [ ] **Step 6.1: Replace `README.md` with the new version**

Overwrite `README.md` with:

```markdown
# nix-darwin Configuration

Personal nix-darwin flake managing macOS systems for `galvin`. Declarative system packages, Homebrew casks/brews, macOS defaults, and a home-manager user environment. Currently serves two hosts: `Galvin-MacBook-Pro` (primary) and `Galvin-MacBook-Pro-2024` (retiring). Designed to absorb NixOS hosts without another rewrite.

If you're forking this for your own machine, see [Adapting for your Mac](#adapting-for-your-mac).

## What you get

- System packages via nixpkgs (CLI tools, dev toolchains)
- GUI apps and macOS-integrated services via Homebrew casks/brews
- Zsh + oh-my-zsh + Starship + Atuin shell history
- Touch ID / Apple Watch for `sudo`
- macOS system defaults (Dock, Finder, hot corners, dark mode, etc.)
- Automatic Nix GC and store optimisation
- Auto-installed Claude CLI and Codex CLI via home-manager activation
- Declarative Backblaze exclusion rules

## Architecture (durable design decisions)

The structure is deliberately small and explicit. Five decisions you should not undo without discussion:

1. **Unified multi-host flake.** Hosts are declared as data in `os/*.nix`; `flake.nix` iterates through a shared `mkConfiguration` helper. Adding a host is editing a list, not editing `flake.nix`. Darwin and NixOS flow through the same code path — when NixOS hosts arrive, `os/nixos.nix` slots in alongside `os/darwin.nix`.

2. **Thin host shells + shared role bundles.** `hosts/<os>/<role>/default.nix` holds only host identity (hostname selection, `primaryUser`, `stateVersion`, `nixpkgs.hostPlatform`). The bulk lives in `core/mbp-darwin-core.nix` (system) and `home/mbp-darwin-home.nix` (home-manager). Host-specific divergence, if ever needed, goes in the thin shell — not the shared bundle.

3. **Platform-first module layout.** `core/darwin/` holds macOS-only system modules (homebrew, pam, backblaze). `core/nixos/` will appear when the first Linux host lands. `core/common/` is deliberately absent until real duplication forces it.

4. **Deliberate simplicity (non-goals).** No custom options module (e.g. `my-nix.role/tz/network`). No pattern-match helpers for hostname → module resolution. Both are deferred until heterogeneous hosts or 3+ hosts make them pay off. Resist adding them speculatively.

5. **Validation by derivation equality.** Before a structural refactor, capture `nix build --print-out-paths .#darwinConfigurations.<host>.system`. After the refactor, the path must be identical. Any drift means the refactor accidentally changed behavior.

## Prerequisites

1. **Apple Silicon Mac** (aarch64-darwin). Intel Macs need `system = "x86_64-darwin"` in `os/darwin.nix`.
2. **Xcode Command Line Tools**:
   ```sh
   xcode-select --install
   ```
3. **Nix** — install via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer):
   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
   Restart your shell so `nix` is on PATH.
4. **Homebrew** — nix-darwin *manages* Homebrew; it does not install it:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## First-time setup on a new Mac

```sh
# 1. Clone. /etc/nix-darwin is the conventional location.
sudo mkdir -p /etc/nix-darwin
sudo chown "$(whoami):staff" /etc/nix-darwin
git clone git@github.com:GalvinGao/nixos-config.git /etc/nix-darwin
cd /etc/nix-darwin

# 2. (Fork only) Adjust — see "Adapting for your Mac" below.

# 3. Bootstrap nix-darwin on the very first run (use your hostname):
nix run nix-darwin -- switch --flake .#$(scutil --get LocalHostName)

# 4. Open a new shell. `nh` and `darwin-rebuild` are on PATH.
exec $SHELL -l
```

After bootstrap, use the Makefile.

## Daily commands

```sh
make switch   # Rebuild and activate (nh darwin switch .)
make update   # Bump flake.lock (nix flake update)
make drift    # Audit installed vs declared state (./detect-drift.sh)
```

`darwin-rebuild` reads the hostname from the running system — no `--flake .#<hostname>` needed.

## Repository layout

```
flake.nix                         Tiny — iterates os/*.nix through mkConfiguration.
os/
  darwin.nix                      Data: list of Darwin systems with host lists and
                                  a moduleResolver that maps hostname -> host dir.

hosts/
  darwin/
    mbp-primary/default.nix       Thin shell for Galvin-MacBook-Pro.
    mbp-2024/default.nix          Thin shell for Galvin-MacBook-Pro-2024.

core/
  darwin/                         macOS-only system modules.
    default.nix                     Imports backblaze, homebrew, pam.
    backblaze.nix                   Deploys Backblaze exclusion rules.
    bzexcluderules_editable.xml     Exclusion list (node_modules, caches, …).
    homebrew.nix                    Taps, brews, casks (declarative).
    pam.nix                         Touch ID + Apple Watch for sudo.
  mbp-darwin-core.nix             Shared Darwin workstation bundle: imports
                                  core/darwin, overlays, system.defaults,
                                  environment.systemPackages, nix GC/optimise,
                                  users.users.galvin.

home/
  terminal/                       Cross-platform home-manager modules.
    zsh.nix                         Zsh: oh-my-zsh, aliases, PATH, fnm init.
    starship.nix                    Starship prompt.
    atuin.nix                       Atuin shell history.
  mbp-darwin-home.nix             Shared Darwin workstation home-manager bundle:
                                  wires home-manager; imports home/terminal/*;
                                  declares home.packages, programs.*, activation.

detect-drift.sh                   Validates nix config vs actual installed state.
print-missing-brew.sh             Lists brew packages declared but not installed.
Makefile                          switch / update / drift shortcuts.
```

## Where to add new things

| You want to install… | Put it in |
|---|---|
| A CLI tool (`jq`, `ripgrep`, `kubectl`, …) | `home.packages` in `home/mbp-darwin-home.nix` |
| A system-wide tool (vim, nano, terminal-notifier) | `environment.systemPackages` in `core/mbp-darwin-core.nix` |
| A GUI app (Ghostty, Arc, 1Password, …) | `casks` in `core/darwin/homebrew.nix` |
| A daemon managed by `brew services` (databases, nats, …) | `brews` in `core/darwin/homebrew.nix` |
| Something needing a custom installer (npm global, curl \| sh) | `home.activation.*` in `home/mbp-darwin-home.nix` |
| A macOS system default | `system.defaults` in `core/mbp-darwin-core.nix` |
| A new Darwin host | Append hostname to `os/darwin.nix` + create `hosts/darwin/<role>/default.nix` |

**Prefer nix packages.** Fall back to Homebrew when a package doesn't build on nix-darwin or needs macOS-specific integration (LaunchDaemons, brew services, GUI app bundles).

## Adapting for your Mac

If you're forking this, five things change:

1. **Hostname.** Add your `scutil --get LocalHostName` value to the `hosts` list in `os/darwin.nix` and add a matching branch in `moduleResolver`.
2. **Username.** Search-replace `galvin` across:
   - `home/mbp-darwin-home.nix` (`home.username`, `home.homeDirectory`, `home-manager.users.galvin`)
   - `core/mbp-darwin-core.nix` (`users.users.galvin`)
   - The thin shell (`system.primaryUser`)
3. **Architecture.** Intel Macs need `system = "x86_64-darwin"` in `os/darwin.nix` and `nixpkgs.hostPlatform = "x86_64-darwin"` in the thin shell.
4. **Host directory.** Create `hosts/darwin/<your-role>/default.nix` modelled on `mbp-primary/default.nix`.
5. **Strip** activation scripts you don't want (`installClaudeCli`, `installCodexCli`), Backblaze (`core/darwin/backblaze.nix`), and any casks/brews specific to my setup.

## Troubleshooting

- **`command not found: darwin-rebuild`** after first install — open a new shell; activation only affects future sessions.
- **Homebrew errors about untrusted paths** — ensure Homebrew is installed *before* `make switch`.
- **Build cache missing a package** — `nix flake update`, then `make switch`.
- **Something installed via `brew install` keeps disappearing** — that's `onActivation.cleanup = "uninstall"` at work. Add the package to `core/darwin/homebrew.nix` to declare it.
- **`Refusing to untap <tap>`** — the tap still has a formula/cask installed. Add the tap to `taps = [ … ]` in `core/darwin/homebrew.nix`.
- **Refactor produced a different derivation hash** — run `nix store diff-closures $OLD $NEW` to see which packages changed. Usually a missed import or reordered attribute.
- **Drift between declared and installed state** — `make drift`.

## References

- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [Determinate Systems Nix installer](https://github.com/DeterminateSystems/nix-installer)
- [Search nixpkgs](https://search.nixos.org/packages)
- [nix-darwin options](https://daiderd.com/nix-darwin/manual/)
```

- [ ] **Step 6.2: Commit**

```sh
git add README.md
git commit -m "docs: rewrite README for multi-host unified layout

Capture the five durable design decisions (unified flake, thin shells,
platform-first modules, deliberate simplicity, derivation-equality
validation) so they survive in the living reference, not just in the
spec."
```

---

## Task 7 — Rewrite `AGENTS.md`

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 7.1: Replace `AGENTS.md` with the new version**

Overwrite `AGENTS.md` with:

```markdown
# nix-darwin Configuration

Personal nix-darwin flake managing macOS systems for `galvin`. Serves two Darwin hosts today (`Galvin-MacBook-Pro`, `Galvin-MacBook-Pro-2024`) and is structured to absorb NixOS hosts without another rewrite.

## Quick Commands

```
make switch   # nh darwin switch .
make update   # nix flake update
make drift    # ./detect-drift.sh
```

## Architecture (durable design decisions)

1. **Unified multi-host flake.** Hosts are data in `os/*.nix`; `flake.nix` iterates through `mkConfiguration`. Adding a host = editing a list, not editing `flake.nix`. Darwin and NixOS flow through the same helper.
2. **Thin host shells + shared role bundles.** `hosts/<os>/<role>/default.nix` holds only host identity (hostname, `primaryUser`, `stateVersion`, platform). The bulk lives in `core/mbp-darwin-core.nix` (system) and `home/mbp-darwin-home.nix` (home-manager).
3. **Platform-first module layout.** `core/darwin/` for macOS-only system modules; `core/nixos/` when needed. No `core/common/` until real duplication appears.
4. **Deliberate simplicity.** No custom options module; no pattern-match helper for hostname → module resolution. Do not add these speculatively.
5. **Validation by derivation equality.** For structural refactors, compare `nix build --print-out-paths .#darwinConfigurations.<host>.system` before and after. Identical path = semantics preserved.

## Repository Structure

```
flake.nix                         Entry point — iterates os/*.nix through mkConfiguration.
flake.lock                        Pinned dependency versions.
Makefile                          switch / update / drift shortcuts.

os/
  darwin.nix                      Data list of Darwin systems: { system, hosts, moduleResolver }.

hosts/
  darwin/
    mbp-primary/default.nix       Thin shell for Galvin-MacBook-Pro.
    mbp-2024/default.nix          Thin shell for Galvin-MacBook-Pro-2024 (retiring).

core/
  darwin/                         macOS-only system modules.
    default.nix                     Imports backblaze, homebrew, pam.
    homebrew.nix                    Homebrew taps, brews, casks.
    pam.nix                         Touch ID + Apple Watch for sudo.
    backblaze.nix                   Backblaze exclusion-rule deployment.
    bzexcluderules_editable.xml     The exclusion list.
  mbp-darwin-core.nix             Shared Darwin workstation bundle: imports core/darwin,
                                  sets allowUnfree, overlays, system.defaults,
                                  environment.systemPackages, users.users.galvin,
                                  nix GC/optimise.

home/
  terminal/                       Cross-platform home-manager modules.
    zsh.nix                         Zsh: oh-my-zsh, aliases, PATH, fnm.
    starship.nix                    Starship prompt.
    atuin.nix                       Atuin shell history.
  mbp-darwin-home.nix             Shared Darwin workstation home-manager bundle:
                                  wires home-manager; imports home/terminal/*;
                                  declares home.packages, programs.*, activation.

detect-drift.sh                   Validates nix config vs actual installed state.
print-missing-brew.sh             Lists declared brew packages not installed.
docs/superpowers/                 Specs and plans (design history; not runtime).
```

## Flake Inputs

| Input | Source |
|---|---|
| nixpkgs | `nixpkgs-unstable` |
| nix-darwin | `nix-darwin/master` |
| home-manager | `nix-community/home-manager` (follows nixpkgs) |
| 1password-shell-plugins | `1Password/shell-plugins` |

## Where Packages Live

Three layers. Prefer nix when available; use Homebrew for things that don't build on nix or need macOS-specific integration.

### 1. Nix system packages — `core/mbp-darwin-core.nix` `environment.systemPackages`
Minimal set: `vim`, `nano`, `terminal-notifier`.

### 2. Nix home-manager packages — `home/mbp-darwin-home.nix` `home.packages`
The bulk of CLI tools: `fnm`, `git`, `go`, `rust`, `python313`, `awscli2`, `kubectl`, `duckdb`, `ffmpeg`, `gh`, `eza`, `jq`, `yq`, `htop`, `tmux`, `wget`, etc. Also nix tooling (`nil`, `nixfmt`, `nh`) and dev utilities (`stripe-cli`, `supabase-cli`, `maestro`, `openfga`).

### 3. Homebrew (brews + casks) — `core/darwin/homebrew.nix`
- **brews**: databases (redis, mysql, postgresql@14/16/17/18, nats-server, mongosh), Kubernetes tools (argocd, talosctl), cocoapods, ampli, node@18 (ampli dependency), dotnet@9, nmap-era tools.
- **casks**: GUI apps — IDEs, browsers, system tools, communication, media, fonts, QuickLook plugins.
- `onActivation.cleanup = "uninstall"` — anything not declared gets uninstalled on switch.
- `onActivation.upgrade = true` — declared packages are upgraded on switch.
- `autoUpdate = false` — no background updates.

### 4. Activation scripts — `home/mbp-darwin-home.nix` `home.activation.*`
For tools installed outside nix/brew:
- `installClaudeCli` — curls the Claude CLI installer.
- `installCodexCli` — `npm i -g @openai/codex`.

## Node.js Setup

- **fnm** is the primary Node version manager (via nix).
- fnm is initialized in zsh with `--corepack-enabled` and `--version-file-strategy=recursive`.
- **node@18** is in Homebrew brews solely as a dependency for `ampli`.
- Global npm bin paths are on PATH: `~/.yarn/bin`, `~/.config/yarn/global/node_modules/.bin`.
- Bun is available via `$BUN_INSTALL/bin`.

## macOS System Defaults

Configured in `core/mbp-darwin-core.nix` `system.defaults`:
- Dark mode, dock autohide, hot corners (Mission Control, Desktop, Launchpad, Start Screen Saver).
- Finder: show all files/extensions, column view, no external drives on desktop.
- Touch ID + Watch ID for sudo (via `core/darwin/pam.nix`).
- Analog menu bar clock, no day of week.

## Shell Environment (`home/terminal/zsh.nix`)

- **Theme**: edvardm (oh-my-zsh).
- **Plugins**: autojump, doctl, docker-compose, fzf, git, gitignore, macos, pod, tmux, rust, yarn.
- **Aliases**: `k`=kubectl, `n`=npm, `p`=pnpm, `ls`=eza, `ll`=eza long, `nr`=npm run.
- **Functions**: `gi` (gitignore.io), `gtp` (tag+push), `gitbump` (semver bump), `listening` (lsof ports), `git-https`/`git-ssh` (remote URL toggle).
- **PATH**: dotnet, postgresql@16, yarn, go, Android SDK, Rust/cargo, bun, fnm node, clamav, `~/Static/PATH`, `~/.local/bin`, `~/.bin`.

## Nix Maintenance

- GC: automatic, every 3 hours, deletes older than 15 days.
- Optimise: automatic, every 4 hours.
- Experimental features: `nix-command flakes`.
- Unfree packages allowed.

## Overlays

- `python3Packages.jeepney` — checks disabled (fails on macOS).
- `nushell` — checks disabled. nushell 0.112 SHLVL tests fail in the Nix sandbox on macOS; nushell is pulled transitively via `bat-extras → batgrep`.

## Editing Guidelines

- When adding a CLI tool: prefer `home.packages` in `home/mbp-darwin-home.nix`. Fall back to `core/darwin/homebrew.nix` brews if it doesn't build on nix or needs a tap.
- When adding a GUI app: add to `core/darwin/homebrew.nix` casks.
- When adding a tool that needs a custom installer (npm global, curl script): add an activation script in `home/mbp-darwin-home.nix` under `home.activation.*`.
- When adding a macOS system default: add to `core/mbp-darwin-core.nix` `system.defaults`.
- When adding a host: append the hostname to `os/darwin.nix` `hosts = [ … ]` and extend `moduleResolver` to map it to a directory under `hosts/darwin/`. Create the thin shell (model it after `hosts/darwin/mbp-primary/default.nix`).
- When a user gives an imperative install command (e.g. `brew install rtk`), treat it as a declarative update request. Edit the corresponding nix file rather than only running the command.
- After changes: run `make switch` to apply.
- If `make` completes without issues, stage the user-requested changes and create a commit.
- For structural refactors: capture the baseline derivation path before, verify parity after. See Architecture decision #5.
- Keep `core/darwin/homebrew.nix` comments consistent with existing category groupings.

## Non-Goals

These are deliberately absent. Do not add them without revisiting the architecture decisions:

- No custom options module (e.g. `my-nix.role`, `my-nix.tz`). Host variation is too small today.
- No pattern-match helper for hostname → directory resolution. Two hosts don't justify it.
- No `core/common/` directory until NixOS hosts prove real system-module duplication.
```

- [ ] **Step 7.2: Commit**

```sh
git add AGENTS.md
git commit -m "docs: rewrite AGENTS.md for multi-host unified layout

Update 'Where Packages Live' and 'Editing Guidelines' with new paths.
Add durable design decisions + explicit non-goals so future agents
don't speculatively add options schemas or match helpers."
```

---

## Task 8 — Final validation and merge

**Files:**
- No file edits.

- [ ] **Step 8.1: Rebuild both configurations**

```sh
nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro.system
nix build --no-link --print-out-paths .#darwinConfigurations.Galvin-MacBook-Pro-2024.system
```

Expected: both succeed. Both paths should be identical to each other.

- [ ] **Step 8.2: Run `nix flake check`**

```sh
nix flake check --no-build
```

Expected: no errors.

- [ ] **Step 8.3: Switch one more time to confirm clean activation**

```sh
sudo nh darwin switch .
```

Expected: no new errors, generation increments.

- [ ] **Step 8.4: Run `make drift` and review**

```sh
make drift | head -60
```

Expected: drift report produced without path errors.

- [ ] **Step 8.5: Merge the branch**

```sh
git checkout main
git merge --no-ff refactor/multi-host-unified -m "refactor: multi-host unified configuration

Adopts data-driven flake + thin host shells from the spec at
docs/superpowers/specs/2026-04-17-multi-host-unified-design.md.
Both Darwin hosts build to identical derivations; divergence room
lives in the thin shells. Ready to absorb NixOS hosts via os/nixos.nix."
git push origin main
```

- [ ] **Step 8.6: Delete the working branch**

```sh
git branch -d refactor/multi-host-unified
git push origin --delete refactor/multi-host-unified
```

---

## Self-Review Notes

- **Spec coverage:** Every item in the spec's Migration Steps (1–10) is covered — creating `os/darwin.nix` (Task 4), `core/mbp-darwin-core.nix` (Task 3), `home/mbp-darwin-home.nix` (Task 2), the thin shells (Task 4), flake rewrite (Task 4), deleting the old host file (Task 4), the three `detect-drift.sh` patches (Task 5), `README.md` (Task 6), `AGENTS.md` (Task 7), and the dual `make switch` validation (Tasks 4.8 + 8.3). The five durable decisions from the spec's Step 8 expansion are reflected in both `README.md` and `AGENTS.md` rewrites.
- **Type consistency:** File paths used across tasks match — `home/mbp-darwin-home.nix`, `core/mbp-darwin-core.nix`, `hosts/darwin/mbp-primary/default.nix`, `hosts/darwin/mbp-2024/default.nix`, `os/darwin.nix` are spelled identically everywhere they appear. The thin shells' relative import paths (`./../../../core/...`) are consistent between the two shells (they're at the same depth).
- **No placeholders:** Every code block is complete. No "TODO", no "similar to above". The Nix code in each task is what gets pasted into the file.
- **Risk surface:** The transitional tasks (2 and 3) keep the old flake entry point working while extracting content, so each commit builds the same derivation as HEAD~1. Task 4 is the single structural swap — protected by derivation-equality check (Step 4.6).
