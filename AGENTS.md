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
5. **Validation by closure equality.** For structural refactors, compare runtime closures (`nix-store -q --requisites`) before and after. Identical package paths (excluding 4 hash-cascade artifacts) = semantics preserved.

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
- For structural refactors: capture the baseline closure before, verify parity after. See Architecture decision #5.
- Keep `core/darwin/homebrew.nix` comments consistent with existing category groupings.

## Non-Goals

These are deliberately absent. Do not add them without revisiting the architecture decisions:

- No custom options module (e.g. `my-nix.role`, `my-nix.tz`). Host variation is too small today.
- No pattern-match helper for hostname → directory resolution. Two hosts don't justify it.
- No `core/common/` directory until NixOS hosts prove real system-module duplication.
