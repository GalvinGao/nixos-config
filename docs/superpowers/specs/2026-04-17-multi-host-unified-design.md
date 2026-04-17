# Multi-Host Unified Configuration Design

**Date:** 2026-04-17
**Status:** Approved — ready for implementation plan

## Goal

Restructure this nix-darwin flake so it:

1. Serves two macOS hosts (`Galvin-MacBook-Pro`, `Galvin-MacBook-Pro-2024`) today — currently identical, with `mbp-primary` being migrated to and `mbp-2024` slated for retirement.
2. Is ready to absorb NixOS hosts in the near future without another structural rewrite.

## Non-Goals

- No per-host divergence in behavior today. Both Darwin hosts produce identical activations.
- No custom options module (`alisa-nix`-style `options.my-nix.*`) — premature for current variation.
- No pattern-match helper (`func/match`) — overkill at two hosts.
- No NixOS modules or hosts written in this change. Only leave the seams for them.

## Inspiration

Structure inspired by `/Users/galvin/Projects/AlisaAkiron-nixos-config`, adopting two patterns from that repo:

1. **`os/*.nix` as data + generic `mkConfiguration`** in `flake.nix` — scales from 1 to N hosts across Darwin and NixOS with no edits to `flake.nix`.
2. **Thin per-host shells** that import shared "role bundle" modules (`core/<role>-core.nix`, `home/<role>-home.nix`).

Deliberately **not** adopted:

- `options/` with `mkOption` schemas — no heterogeneous hosts to justify it.
- `func/match.nix` — two hosts don't need a pattern-match library.

## Target Layout

```
flake.nix                         # Tiny. Iterates os/*.nix -> darwinConfigurations
                                  #   (nixosConfigurations added later when the first
                                  #   Linux host lands).
os/
  darwin.nix                      # Data: [{ system, hosts, moduleResolver }]
                                  #   for all Darwin hosts.

hosts/
  darwin/
    mbp-primary/default.nix       # Thin shell for Galvin-MacBook-Pro
    mbp-2024/default.nix          # Thin shell for Galvin-MacBook-Pro-2024
  # nixos/                        # Future — created when first Linux host lands.

core/
  darwin/                         # macOS-only system modules (already exists today)
    default.nix                   # Imports backblaze, homebrew, pam.
    backblaze.nix
    bzexcluderules_editable.xml
    homebrew.nix
    pam.nix
  mbp-darwin-core.nix             # NEW: "Darwin workstation" bundle. Imports
                                  #   core/darwin, sets allowUnfree, overlays,
                                  #   system.defaults, nix GC/optimise, and
                                  #   wires home-manager.

home/
  terminal/                       # Unchanged (zsh, starship, atuin).
  mbp-darwin-home.nix             # NEW: home-manager user bundle. Imports
                                  #   home/terminal/*, declares home.packages,
                                  #   programs.bat / programs.fzf, and
                                  #   Claude/Codex activation scripts.
```

## `flake.nix`

Replaces the current per-host literal with a data-driven loop:

```nix
outputs = { nixpkgs, nix-darwin, ... }@inputs:
  let
    darwinSystems = import ./os/darwin.nix;

    mkConfiguration = { systems, mkSystem }:
      builtins.listToAttrs (builtins.concatMap (sys:
        builtins.map (host: {
          name = host;
          value = mkSystem {
            system = sys.system;
            specialArgs = { inherit inputs; };
            modules = sys.moduleResolver host;
          };
        }) sys.hosts
      ) systems);
  in {
    darwinConfigurations = mkConfiguration {
      systems = darwinSystems;
      mkSystem = nix-darwin.lib.darwinSystem;
    };

    homeManagerModules = {
      _1password-shell-plugins = inputs._1password-shell-plugins.hmModules.default;
    };
  };
```

Adding NixOS later = write `os/nixos.nix`, add one `mkConfiguration` call.

## `os/darwin.nix`

```nix
[
  {
    system = "aarch64-darwin";
    hosts = [
      "Galvin-MacBook-Pro"
      "Galvin-MacBook-Pro-2024"
    ];
    moduleResolver = host: [
      (./.. + "/hosts/darwin/${
        if host == "Galvin-MacBook-Pro" then "mbp-primary" else "mbp-2024"
      }")
    ];
  }
]
```

The hostname → directory mapping is a single inline conditional. When a third Darwin host arrives, add to both the `hosts` list and the conditional (or convert to an attrset if it grows past 3).

## Thin host shells

`hosts/darwin/mbp-primary/default.nix` and `hosts/darwin/mbp-2024/default.nix` are byte-identical today:

```nix
{ inputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ../../../core/mbp-darwin-core.nix
    ../../../home/mbp-darwin-home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "galvin";
  system.stateVersion = 6;
}
```

When `mbp-2024` retires: delete the directory, delete the string from `os/darwin.nix`. No shared-module changes.

If a host ever needs a one-off tweak (extra cask, different `screencapture.location`, different `home.activation.*`), it goes here — the shell is the designated place for host-specific overrides.

## `core/mbp-darwin-core.nix`

Receives everything currently in `hosts/mbp-darwin/default.nix` that is not host-identity:

- `imports = [ ./darwin ]` (picks up `homebrew.nix`, `pam.nix`, `backblaze.nix` via `core/darwin/default.nix`).
- `nixpkgs.config.allowUnfree = true`.
- `environment.systemPackages` (vim, nano, terminal-notifier).
- `nix.settings.experimental-features = "nix-command flakes"`.
- `system.defaults` block.
- `nixpkgs.overlays` (jeepney + nushell).
- `home-manager = { useGlobalPkgs, useUserPackages, extraSpecialArgs, users.galvin = import ../home/mbp-darwin-home.nix; }`.
- `users.users.galvin` identity.
- `nix.gc.*`, `nix.optimise.*`.

Does **not** receive: `nixpkgs.hostPlatform`, `system.primaryUser`, `system.stateVersion` — those stay in the host shell so they can diverge if ever needed.

## `home/mbp-darwin-home.nix`

Receives the `home-manager.users.galvin = { … }` block body:

- `imports = [ ../home/terminal/zsh.nix ../home/terminal/starship.nix ../home/terminal/atuin.nix ]`.
- `home.username = "galvin"`, `home.homeDirectory = "/Users/galvin"`, `home.stateVersion = "25.05"`.
- `home.activation.installClaudeCli`, `home.activation.installCodexCli`.
- `programs.home-manager.enable`, `programs.fzf`, `programs.bat`.
- `home.packages` (the full CLI tool list).

## Migration steps

1. Create `os/darwin.nix`.
2. Create `core/mbp-darwin-core.nix` (move content out of `hosts/mbp-darwin/default.nix`).
3. Create `home/mbp-darwin-home.nix` (move the home-manager user block).
4. Create `hosts/darwin/mbp-primary/default.nix` and `hosts/darwin/mbp-2024/default.nix`.
5. Rewrite `flake.nix` with `mkConfiguration`.
6. Delete `hosts/mbp-darwin/default.nix` (all content has moved).
7. Patch `detect-drift.sh`:
   - line 7: `HOST_NIX="$REPO_DIR/home/mbp-darwin-home.nix"`. `HOST_NIX` is used once (line 262) to extract the `home.packages` list — which lives in the home bundle after the split. `HOMEBREW_NIX` stays pointed at `core/darwin/homebrew.nix` (unchanged).
   - line 129: display string (`Galvin-MacBook-Pro`) — make host-agnostic or read from `scutil --get LocalHostName`.
   - line 681: guidance message referencing `hosts/mbp-darwin/default.nix` — update to point at the correct new file for `system.defaults` (which moves to `core/mbp-darwin-core.nix`).
8. Update `README.md` and `AGENTS.md` to reflect the new structure **and the durable design decisions** — these two docs are the repo's living reference. The spec is a point-in-time record; the README and AGENTS are what every future reader (human or agent) lands on first.

   Both docs should make the following decisions explicit:

   - **Unified multi-host flake.** Hosts are declared as data in `os/*.nix`; `flake.nix` iterates and builds all configurations. Adding a host is editing a list, not editing `flake.nix`. Both Darwin and NixOS flow through the same `mkConfiguration`.
   - **Thin host shells + shared role bundles.** `hosts/<os>/<role>/default.nix` holds only host identity (hostname, `primaryUser`, `stateVersion`, platform). The bulk of the configuration lives in `core/<role>-<os>-core.nix` and `home/<role>-<os>-home.nix`. Host-specific divergence (if it ever arises) goes in the thin shell, not the shared bundle.
   - **Platform-first module organization.** `core/darwin/` holds macOS-only system modules (homebrew, pam, backblaze). `core/nixos/` will appear when the first Linux host lands. `core/common/` is deliberately absent until real duplication forces it.
   - **Deliberate simplicity (explicit non-goals).** No custom options module (`my-nix.role/tz/network`). No pattern-match helpers. These are deferred until heterogeneous hosts or 3+ hosts make them pay off. Call this out so future contributors don't add them speculatively.
   - **Where packages live, updated.** `AGENTS.md`'s "Where Packages Live" and "Editing Guidelines" sections need new paths (`core/mbp-darwin-core.nix` `environment.systemPackages`, `home/mbp-darwin-home.nix` `home.packages`, etc.). The "prefer nix over homebrew" guidance stays as-is.
   - **Adapting for a new Mac / new host, updated.** `README.md`'s "Adapting for your Mac" section currently says to rename one key in `flake.nix`. Under the new structure, adapting = adding a string to `os/darwin.nix` and creating a thin shell in `hosts/darwin/<role>/`. Rewrite that section.
9. `make switch` on `mbp-primary` to validate.
10. `make switch` on `mbp-2024` (before retirement, to confirm parity).

## Validation

- `nix flake check .` passes.
- `darwin-rebuild build --flake .#Galvin-MacBook-Pro` builds on `mbp-primary`.
- `darwin-rebuild build --flake .#Galvin-MacBook-Pro-2024` builds on `mbp-2024`.
- `make switch` on each machine produces a new generation with the same activation output shape as generation 114 (no new errors, no new warnings).
- `detect-drift.sh` runs without path errors.

## Rollback

Pure file-move refactor. If `make switch` fails:

- `git reset --hard HEAD~1` restores the working tree.
- `darwin-rebuild --rollback` or `sudo darwin-rebuild switch --flake . --rollback` restores the previous generation on the live system.

## Future (out of scope for this change)

- `os/nixos.nix` for the first Linux host.
- Split shared `core/common/` (cross-platform nix settings) from `core/darwin/` when NixOS lands and we see actual duplication.
- Per-host divergence (`mbp-primary` vs `mbp-2024`) — naturally belongs in the thin shells if it ever arises.
- Custom options module if host variation grows enough to justify an interface.
