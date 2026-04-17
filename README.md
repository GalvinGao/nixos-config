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

5. **Validation by closure equality.** Structural refactors compare runtime closures, not derivation hashes. Capture `nix-store -q --requisites $(nix build --print-out-paths .#darwinConfigurations.<host>.system)` before the refactor; afterward, every non-artifact store path must match. Four hash-cascade artifacts (`darwin-system`, `system-path`, `etc`, `system-applications`) are allowed to differ — they reflect benign module-merge-order effects, not behavior changes.

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
