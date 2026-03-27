# nix-darwin Configuration

Personal nix-darwin flake managing a macOS (aarch64-darwin) system for user `galvin` on `Galvin-MacBook-Pro`.

## Quick Commands

```
make switch   # nh darwin switch .
make update   # nix flake update
make drift    # ./detect-drift.sh
```

## Repository Structure

```
flake.nix                         # Entry point — darwinSystem + home-manager inputs
flake.lock                        # Pinned dependency versions
Makefile                          # switch / update / drift shortcuts

hosts/mbp-darwin/default.nix      # Host config: system packages, macOS defaults,
                                  #   overlays, home-manager user config, activation
                                  #   scripts, and nix GC/optimise settings

core/darwin/
  default.nix                     # Imports homebrew.nix + pam.nix
  homebrew.nix                    # Homebrew taps, brews, casks (declarative)
  pam.nix                         # Touch ID + Watch ID for sudo

home/terminal/
  zsh.nix                         # Zsh: oh-my-zsh, aliases, PATH, shell functions, fnm
  starship.nix                    # Starship prompt symbols and git status format
  atuin.nix                       # Atuin shell history (up-arrow disabled)

scripts/                          # Helper scripts (currently empty)
detect-drift.sh                   # Validates nix config vs actual installed state
print-missing-brew.sh             # Lists brew packages declared but not installed
```

## Flake Inputs

| Input | Source |
|---|---|
| nixpkgs | `nixpkgs-unstable` |
| nix-darwin | `nix-darwin/master` |
| home-manager | `nix-community/home-manager` (follows nixpkgs) |
| 1password-shell-plugins | `1Password/shell-plugins` |

## Where Packages Live

There are three layers for installing packages. Prefer nix packages when available; use Homebrew for things that don't build well with nix or need macOS-specific integration.

### 1. Nix system packages — `hosts/mbp-darwin/default.nix` `environment.systemPackages`
Minimal set: vim, nano, terminal-notifier.

### 2. Nix home-manager packages — `hosts/mbp-darwin/default.nix` `home.packages`
The bulk of CLI tools: fnm, git, go, rust, python313, awscli2, kubectl, duckdb, ffmpeg, gh, eza, jq, yq, htop, tmux, wget, etc. Also nix tooling (nil, nixfmt, nh) and dev utilities (stripe-cli, supabase-cli, maestro, openfga).

### 3. Homebrew (brews + casks) — `core/darwin/homebrew.nix`
- **brews**: databases (redis, mysql, postgresql@14/16/17/18, nats-server, mongosh), Kubernetes tools (helm, kubectx, kubeseal, argocd, talosctl), cocoapods, ampli, node@18 (ampli dependency), dotnet@9, swiftlint, swiftformat, nmap, opencode, zellij, prek.
- **casks**: 100+ GUI apps — IDEs, browsers, system tools, communication, media, fonts, QuickLook plugins.
- `onActivation.cleanup = "uninstall"` — any brew/cask removed from config gets uninstalled on switch.
- `onActivation.upgrade = true` — existing packages get upgraded on switch.
- `autoUpdate = false` — no background brew updates.

### 4. Activation scripts — `hosts/mbp-darwin/default.nix` `home.activation.*`
Used for tools installed outside nix/brew:
- `installClaudeCli` — installs Claude CLI via curl
- `installCodexCli` — installs `@openai/codex` via npm (using `pkgs.nodejs_22`)

## Node.js Setup

- **fnm** (Fast Node Manager) is the primary Node version manager, installed via nix
- fnm is initialized in zsh with `--corepack-enabled` and `--version-file-strategy=recursive`
- **node@18** is in Homebrew brews solely as a dependency for `ampli`
- Global npm bin paths are on PATH: `~/.yarn/bin`, `~/.config/yarn/global/node_modules/.bin`
- Bun is also available (`$BUN_INSTALL/bin`)

## macOS System Defaults

Configured in `hosts/mbp-darwin/default.nix` `system.defaults`:
- Dark mode, dock autohide, hot corners (Mission Control, Desktop, Launchpad, Start Screen Saver)
- Finder: show all files/extensions, column view, no external drives on desktop
- Touch ID + Watch ID for sudo (via `pam.nix`)
- Analog menu bar clock, no day of week

## Shell Environment (zsh.nix)

- **Theme**: edvardm (oh-my-zsh)
- **Plugins**: autojump, doctl, docker-compose, fzf, git, gitignore, macos, pod, tmux, rust, yarn
- **Key aliases**: `k`=kubectl, `n`=npm, `p`=pnpm, `ls`=eza, `ll`=eza long, `nr`=npm run
- **Functions**: `gi` (gitignore.io), `gtp` (tag+push), `gitbump` (semver bump), `listening` (lsof ports), `git-https`/`git-ssh` (remote URL toggle)
- **PATH**: dotnet, postgresql@16, yarn, go, Android SDK, Rust/cargo, bun, fnm node, clamav, `~/Static/PATH`, `~/.local/bin`, `~/.bin`

## Nix Maintenance

- GC: automatic, every 3 hours, deletes older than 15 days
- Optimise: automatic, every 4 hours
- Experimental features: `nix-command flakes`
- Unfree packages allowed

## Overlays

- `python3Packages.jeepney` — checks disabled (fails on macOS)

## Editing Guidelines

- When adding a CLI tool: prefer `home.packages` in `hosts/mbp-darwin/default.nix`. Fall back to `homebrew.nix` brews if it doesn't build on nix or needs a tap.
- When adding a GUI app: add to `homebrew.nix` casks.
- When adding a tool that needs a custom install (npm global, curl script, etc.): add an activation script in `hosts/mbp-darwin/default.nix`.
- After changes: run `make switch` to apply.
- Keep `homebrew.nix` comments consistent with existing category groupings.
