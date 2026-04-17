#!/usr/bin/env bash
set -uo pipefail

# ── Config ───────────────────────────────────────────────────────────
REPO_DIR="/etc/nix-darwin"
HOMEBREW_NIX="$REPO_DIR/core/darwin/homebrew.nix"
HOST_NIX="$REPO_DIR/home/mbp-darwin-home.nix"
FLAKE_LOCK="$REPO_DIR/flake.lock"
HM_BIN="/etc/profiles/per-user/galvin/bin"
SYSTEM_BIN="/run/current-system/sw/bin"
FLAKE_AGE_WARN_DAYS=30

# ── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Counters ─────────────────────────────────────────────────────────
PASS=0
FAIL=0
WARN=0

# ── Helpers ──────────────────────────────────────────────────────────
pass() { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; ((WARN++)); }

section() {
  echo ""
  echo -e "${CYAN}── $1 ──────────────────────────────────────${NC}"
}

command_exists() { command -v "$1" &>/dev/null; }

# Parse a nix array from a file: parse_nix_array <file> <array_name>
# Extracts quoted strings between `<name> = [` and `];`
parse_nix_array() {
  local file="$1" name="$2"
  sed -n "/${name} = \\[/,/\\];/p" "$file" \
    | grep -E '^\s*"[^"]+"' \
    | sed 's/.*"\([^"]*\)".*/\1/' \
    | sort -u
}

# Strip tap prefix: "siderolabs/tap/talosctl" -> "talosctl"
strip_tap_prefix() { echo "$1" | sed 's|.*/||'; }

# Extract implicit taps from prefixed entries: "siderolabs/tap/talosctl" -> "siderolabs/tap"
extract_implicit_taps() {
  echo "$1" | grep '/' | sed 's|/[^/]*$||' | sort -u
}

# Check a macOS default: check_default <domain> <key> <expected> <label>
check_default() {
  local domain="$1" key="$2" expected="$3" label="$4"
  local actual
  actual=$(defaults read "$domain" "$key" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    warn "${label}: key not set ${DIM}(${domain} ${key})${NC}"
  elif [[ "$actual" == "$expected" ]]; then
    pass "${label} = ${expected} ${DIM}(${domain} ${key})${NC}"
  else
    fail "${label}: expected ${expected}, got ${actual} ${DIM}(${domain} ${key})${NC}"
  fi
}

# Dependency patterns to ignore for "extra on system" brew check
DEPENDENCY_PATTERNS=(
  '^lib' '^ca-certificates$' '^certifi$' '^gettext$' '^ncurses$'
  '^openssl' '^pcre' '^readline$' '^sqlite$' '^xz$' '^zlib$' '^zstd$'
  '^c-ares$' '^cffi$' '^cryptography$' '^mpdecimal$'
  '^pycparser$' '^cairo$' '^fontconfig$' '^freetype$' '^fribidi$'
  '^giflib$' '^glib$' '^gmp$' '^gnutls$' '^graphite2$' '^harfbuzz$'
  '^highway$' '^icu4c' '^imath$' '^jpeg' '^krb5$' '^lz4$' '^lzo$'
  '^mbedtls$' '^nettle$' '^p11-kit$' '^pango$' '^pixman$' '^webp$'
  '^xorgproto$' '^abseil$' '^aom$' '^aribb24$' '^dav1d$' '^flac$'
  '^frei0r$' '^lame$' '^leptonica$' '^little-cms2$' '^mpg123$'
  '^opencore-amr$' '^openexr$' '^openjpeg$' '^opus$' '^rav1e$'
  '^rubberband$' '^sdl2$' '^simdjson$' '^snappy$' '^speex$' '^srt$'
  '^svt-av1$' '^tesseract$' '^theora$' '^unbound$' '^uvwasi$'
  '^x264$' '^x265$' '^xvid$' '^zeromq$' '^zimg$' '^zopfli$'
  '^cjson$' '^pkgconf$'
)

is_likely_dependency() {
  local pkg="$1"
  for pattern in "${DEPENDENCY_PATTERNS[@]}"; do
    if [[ $pkg =~ $pattern ]]; then return 0; fi
  done
  return 1
}

# Package-to-binary mapping for home-manager packages where they differ
declare -A BIN_MAP=(
  [p7zip]="7z"
  [python313]="python3.13"
  [supabase-cli]="supabase"
  [stripe-cli]="stripe"
  [xxHash]="xxhsum"
  [awscli2]="aws"
  [inetutils]="telnet"
  [imagemagick]="magick"
  [openjdk]="java"
  [ast-grep]="ast-grep"
  [rabbitmq-server]="rabbitmqctl"
  [speedtest-cli]="speedtest-cli"
  [grpc]="grpc_cpp_plugin"
  [pixman]="SKIP"
  [git-lfs]="git-lfs"
  [pkg-config]="pkg-config"
  [arp-scan]="arp-scan"
  [yt-dlp]="yt-dlp"
  [erlang]="erl"
  [exiftool]="exiftool"
  [aria2]="aria2c"
  [iperf]="iperf"
  [iperf3]="iperf3"
)

# ═════════════════════════════════════════════════════════════════════
echo -e "${BOLD}"
echo "══════════════════════════════════════════════════"
echo "  nix-darwin Drift Report"
echo "  $(scutil --get LocalHostName 2>/dev/null || echo 'nix-darwin')  •  $(date +%Y-%m-%d)"
echo "══════════════════════════════════════════════════"
echo -e "${NC}"

# ═════════════════════════════════════════════════════════════════════
# Section 1: Homebrew
# ═════════════════════════════════════════════════════════════════════
if command_exists brew; then

  # ── 1a: Taps ─────────────────────────────────────────────────────
  section "Homebrew Taps"

  DECLARED_TAPS=$(parse_nix_array "$HOMEBREW_NIX" "taps")
  DECLARED_BREWS=$(parse_nix_array "$HOMEBREW_NIX" "brews")
  DECLARED_CASKS=$(parse_nix_array "$HOMEBREW_NIX" "casks")

  # Build implicit taps from prefixed brews and casks
  IMPLICIT_TAPS=$(printf '%s\n' "$DECLARED_BREWS" "$DECLARED_CASKS" | grep '/' | sed 's|/[^/]*$||' | sort -u)
  ALL_EXPECTED_TAPS=$(printf '%s\n' "$DECLARED_TAPS" "$IMPLICIT_TAPS" | sort -u)

  INSTALLED_TAPS=$(brew tap | sort)

  # Declared/expected but not tapped
  while IFS= read -r tap; do
    [[ -z "$tap" ]] && continue
    if echo "$INSTALLED_TAPS" | grep -qx "$tap"; then
      pass "$tap"
    else
      fail "not tapped: $tap"
    fi
  done <<< "$ALL_EXPECTED_TAPS"

  # Tapped but not declared — collect for later snippet
  UNPERSISTED_TAPS=()
  while IFS= read -r tap; do
    [[ -z "$tap" ]] && continue
    if ! echo "$ALL_EXPECTED_TAPS" | grep -qx "$tap"; then
      if [[ "$tap" == "homebrew/"* ]]; then continue; fi
      warn "extra tap on system: $tap"
      UNPERSISTED_TAPS+=("$tap")
    fi
  done <<< "$INSTALLED_TAPS"

  # ── 1b: Brews ───────────────────────────────────────────────────
  section "Homebrew Formulae"

  # Build a list of stripped brew names
  DECLARED_BREW_NAMES=""
  while IFS= read -r brew; do
    [[ -z "$brew" ]] && continue
    DECLARED_BREW_NAMES+="$(strip_tap_prefix "$brew")"$'\n'
  done <<< "$DECLARED_BREWS"
  DECLARED_BREW_NAMES=$(echo "$DECLARED_BREW_NAMES" | sort -u | sed '/^$/d')

  INSTALLED_FORMULAE=$(brew list --formula | sort)

  # Declared but not installed
  while IFS= read -r brew; do
    [[ -z "$brew" ]] && continue
    if echo "$INSTALLED_FORMULAE" | grep -qx "$brew"; then
      pass "$brew"
    else
      fail "declared but not installed: $brew"
    fi
  done <<< "$DECLARED_BREW_NAMES"

  # Installed but not declared — collect for later snippet
  UNPERSISTED_BREWS=()
  BREW_LEAVES=$(brew leaves 2>/dev/null | sort)
  while IFS= read -r formula; do
    [[ -z "$formula" ]] && continue
    stripped=$(strip_tap_prefix "$formula")
    if ! echo "$DECLARED_BREW_NAMES" | grep -qx "$stripped"; then
      if ! is_likely_dependency "$stripped"; then
        warn "installed but not declared: $formula"
        UNPERSISTED_BREWS+=("$formula")
      fi
    fi
  done <<< "$BREW_LEAVES"

  # ── 1c: Casks ───────────────────────────────────────────────────
  section "Homebrew Casks"

  DECLARED_CASK_NAMES=""
  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue
    DECLARED_CASK_NAMES+="$(strip_tap_prefix "$cask")"$'\n'
  done <<< "$DECLARED_CASKS"
  DECLARED_CASK_NAMES=$(echo "$DECLARED_CASK_NAMES" | sort -u | sed '/^$/d')

  INSTALLED_CASKS=$(brew list --cask | sort)

  # Declared but not installed
  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue
    if echo "$INSTALLED_CASKS" | grep -qx "$cask"; then
      pass "$cask"
    else
      fail "declared but not installed: $cask"
    fi
  done <<< "$DECLARED_CASK_NAMES"

  # Installed but not declared — collect for later snippet
  UNPERSISTED_CASKS=()
  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue
    if ! echo "$DECLARED_CASK_NAMES" | grep -qx "$cask"; then
      warn "installed but not declared: $cask"
      UNPERSISTED_CASKS+=("$cask")
    fi
  done <<< "$INSTALLED_CASKS"

else
  section "Homebrew"
  warn "brew command not found — skipping Homebrew checks"
fi

# ═════════════════════════════════════════════════════════════════════
# Section 2: Nix Packages
# ═════════════════════════════════════════════════════════════════════
section "Nix System Packages"

for pkg in vim nano terminal-notifier; do
  if [[ -e "$SYSTEM_BIN/$pkg" ]]; then
    pass "$pkg"
  else
    fail "missing from system profile: $pkg"
  fi
done

section "Nix Home-Manager Packages"

# Extract home.packages from the nix file (attribute names after `pkgs.`)
HM_PACKAGES=$(sed -n '/home\.packages = with pkgs;/,/\];/p' "$HOST_NIX" \
  | tail -n +2 \
  | grep -v '^\s*\];' \
  | grep -v '^\s*$' \
  | grep -v '^\s*#' \
  | sed 's/#.*//' \
  | sed 's/^[[:space:]]*//' \
  | sed 's/[[:space:]]*$//' \
  | sed '/^$/d' \
  | sort -u)

while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  # Look up binary name
  if [[ -n "${BIN_MAP[$pkg]+x}" ]]; then
    bin="${BIN_MAP[$pkg]}"
    if [[ "$bin" == "SKIP" ]]; then
      pass "$pkg ${DIM}(library, no binary)${NC}"
      continue
    fi
  else
    bin="$pkg"
  fi
  if [[ -e "$HM_BIN/$bin" ]]; then
    pass "$pkg ${DIM}($bin)${NC}"
  else
    # Some packages provide binaries with different names; check `which` as fallback
    if command_exists "$bin"; then
      pass "$pkg ${DIM}($bin, found on PATH)${NC}"
    else
      fail "missing binary for: $pkg ${DIM}(expected: $bin)${NC}"
    fi
  fi
done <<< "$HM_PACKAGES"

# Also check programs enabled via home-manager (fzf, bat, batgrep)
for bin in fzf bat batgrep; do
  if [[ -e "$HM_BIN/$bin" ]]; then
    pass "$bin ${DIM}(program)${NC}"
  else
    fail "missing program binary: $bin"
  fi
done

# ═════════════════════════════════════════════════════════════════════
# Section 3: macOS Defaults
# ═════════════════════════════════════════════════════════════════════
section "macOS Defaults"

check_default "com.apple.dock"   "autohide"                        "1" "Dock: autohide"
check_default "com.apple.dock"   "mru-spaces"                      "1" "Dock: MRU spaces"
check_default "com.apple.finder" "AppleShowAllExtensions"           "1" "Finder: show all extensions"
check_default "com.apple.finder" "AppleShowAllFiles"                "1" "Finder: show hidden files"
check_default "com.apple.finder" "_FXSortFoldersFirst"              "0" "Finder: folders first"
check_default "com.apple.finder" "FXEnableExtensionChangeWarning"   "0" "Finder: extension change warning"
check_default "NSGlobalDomain"   "NSDocumentSaveNewDocumentsToCloud" "0" "Global: save to cloud"
check_default "com.apple.Music"  "userWantsPlaybackNotifications"   "0" "Music: playback notifications"

# ═════════════════════════════════════════════════════════════════════
# Section 4: PAM / Security
# ═════════════════════════════════════════════════════════════════════
section "PAM / Security"

PAM_FILE="/etc/pam.d/sudo_local"
if [[ -f "$PAM_FILE" ]]; then
  pass "sudo_local PAM file exists"
  if grep -q "pam_tid.so" "$PAM_FILE"; then
    pass "Touch ID for sudo"
  else
    fail "Touch ID for sudo: pam_tid.so not found in $PAM_FILE"
  fi
  if grep -q "pam_watchid.so" "$PAM_FILE"; then
    pass "Watch ID for sudo"
  else
    fail "Watch ID for sudo: pam_watchid.so not found in $PAM_FILE"
  fi
else
  fail "sudo_local PAM file missing: $PAM_FILE"
fi

# ═════════════════════════════════════════════════════════════════════
# Section 5: Nix System Health
# ═════════════════════════════════════════════════════════════════════
section "Nix System Health"

# 5a: Generation freshness
SYSTEM_PROFILE="/nix/var/nix/profiles/system"
if [[ -L "$SYSTEM_PROFILE" ]]; then
  PROFILE_MTIME=$(stat -f %m "$SYSTEM_PROFILE" 2>/dev/null || echo 0)
  LATEST_COMMIT_TIME=$(git -C "$REPO_DIR" log -1 --format=%ct 2>/dev/null || echo 0)
  if [[ "$LATEST_COMMIT_TIME" -gt "$PROFILE_MTIME" ]]; then
    DIFF_HOURS=$(( (LATEST_COMMIT_TIME - PROFILE_MTIME) / 3600 ))
    warn "config has commits newer than current generation (${DIFF_HOURS}h behind)"
  else
    pass "system generation is up to date with latest commit"
  fi
else
  warn "system profile not found at $SYSTEM_PROFILE"
fi

# 5b: Uncommitted changes
DIRTY=$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)
if [[ -n "$DIRTY" ]]; then
  NUM_CHANGED=$(echo "$DIRTY" | wc -l | tr -d ' ')
  warn "uncommitted changes in repo (${NUM_CHANGED} file(s))"
  echo "$DIRTY" | while IFS= read -r line; do
    echo -e "      ${DIM}${line}${NC}"
  done
else
  pass "working tree is clean"
fi

# 5c: Flake lock age
if [[ -f "$FLAKE_LOCK" ]] && command_exists jq; then
  NOW=$(date +%s)
  echo ""
  echo -e "  ${DIM}Flake input ages:${NC}"
  jq -r '.nodes | to_entries[] | select(.value.locked.lastModified) | "\(.key) \(.value.locked.lastModified)"' "$FLAKE_LOCK" 2>/dev/null \
    | while read -r name ts; do
        AGE_DAYS=$(( (NOW - ts) / 86400 ))
        if [[ $AGE_DAYS -gt $FLAKE_AGE_WARN_DAYS ]]; then
          warn "flake input '${name}': ${AGE_DAYS} days old"
        else
          pass "flake input '${name}': ${AGE_DAYS} days old"
        fi
      done
else
  if [[ ! -f "$FLAKE_LOCK" ]]; then
    warn "flake.lock not found"
  fi
  if ! command_exists jq; then
    warn "jq not available — skipping flake lock age check"
  fi
fi

# 5d: Nix config
NIX_CONF="/etc/nix/nix.conf"
if [[ -f "$NIX_CONF" ]]; then
  if grep -q "experimental-features.*nix-command.*flakes" "$NIX_CONF"; then
    pass "nix.conf: experimental features enabled"
  else
    fail "nix.conf: experimental-features missing nix-command/flakes"
  fi
else
  warn "nix.conf not found at $NIX_CONF"
fi

# ═════════════════════════════════════════════════════════════════════
# Section 6: Shell Environment
# ═════════════════════════════════════════════════════════════════════
section "Shell Environment"
echo -e "  ${DIM}(reflects current shell session — run from zsh for full accuracy)${NC}"

# 6a: Shell integrations
for bin in starship atuin fzf; do
  if command_exists "$bin"; then
    pass "$bin available"
  else
    fail "$bin not found on PATH"
  fi
done

# 6b: Key env vars
check_env() {
  local var="$1" expected="$2"
  local actual="${!var:-}"
  if [[ -z "$actual" ]]; then
    warn "$var not set ${DIM}(expected: $expected)${NC}"
  elif [[ "$actual" == "$expected" ]]; then
    pass "$var = $expected"
  else
    fail "$var: expected '$expected', got '$actual'"
  fi
}

check_env "EDITOR" "nano"
check_env "HOMEBREW_NO_AUTO_UPDATE" "1"

# 6c: PATH entries
check_path() {
  local dir="$1"
  # Expand $HOME in the dir string
  local expanded="${dir/\$HOME/$HOME}"
  if echo "$PATH" | tr ':' '\n' | grep -qx "$expanded"; then
    pass "PATH contains $dir"
  else
    warn "PATH missing: $dir"
  fi
}

check_path "/opt/homebrew/opt/dotnet@9/bin"
check_path "\$HOME/go/bin"
check_path "\$HOME/.cargo/bin"
check_path "\$HOME/.bun/bin"

# 6d: Oh-My-Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  pass "Oh-My-Zsh installed"
else
  fail "Oh-My-Zsh directory missing (~/.oh-my-zsh)"
fi

# ═════════════════════════════════════════════════════════════════════
# Section 7: Unpersisted Homebrew — nix snippet for copy-paste
# ═════════════════════════════════════════════════════════════════════
HAS_UNPERSISTED=0

if [[ ${#UNPERSISTED_TAPS[@]} -gt 0 ]] || [[ ${#UNPERSISTED_BREWS[@]} -gt 0 ]] || [[ ${#UNPERSISTED_CASKS[@]} -gt 0 ]]; then
  HAS_UNPERSISTED=1
  section "Unpersisted Homebrew — add to homebrew.nix"
  echo -e "  ${DIM}Copy-paste the lines below into the matching arrays in:${NC}"
  echo -e "  ${DIM}${HOMEBREW_NIX}${NC}"

  if [[ ${#UNPERSISTED_TAPS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}taps = [${NC}"
    for tap in "${UNPERSISTED_TAPS[@]}"; do
      echo -e "    ${GREEN}\"$tap\"${NC}"
    done
    echo -e "  ${YELLOW}];${NC}"
  fi

  if [[ ${#UNPERSISTED_BREWS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}brews = [${NC}"
    for brew in "${UNPERSISTED_BREWS[@]}"; do
      echo -e "    ${GREEN}\"$brew\"${NC}"
    done
    echo -e "  ${YELLOW}];${NC}"
  fi

  if [[ ${#UNPERSISTED_CASKS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}casks = [${NC}"
    for cask in "${UNPERSISTED_CASKS[@]}"; do
      echo -e "    ${GREEN}\"$cask\"${NC}"
    done
    echo -e "  ${YELLOW}];${NC}"
  fi
fi

# ═════════════════════════════════════════════════════════════════════
# Section 8: Unmanaged macOS Defaults — system prefs not in nix config
# ═════════════════════════════════════════════════════════════════════
section "Unmanaged macOS Defaults"
echo -e "  ${DIM}Scanning commonly customized preferences not in your nix config...${NC}"
echo ""

# Build a set of already-managed defaults for filtering (domain|key)
declare -A MANAGED_DEFAULTS=(
  ["com.apple.dock|autohide"]=1
  ["com.apple.dock|autohide-delay"]=1
  ["com.apple.dock|mru-spaces"]=1
  ["com.apple.dock|largesize"]=1
  ["com.apple.dock|tilesize"]=1
  ["com.apple.dock|wvous-tl-corner"]=1
  ["com.apple.dock|wvous-tr-corner"]=1
  ["com.apple.dock|wvous-bl-corner"]=1
  ["com.apple.dock|wvous-br-corner"]=1
  ["com.apple.finder|AppleShowAllExtensions"]=1
  ["com.apple.finder|AppleShowAllFiles"]=1
  ["com.apple.finder|_FXSortFoldersFirst"]=1
  ["com.apple.finder|FXEnableExtensionChangeWarning"]=1
  ["com.apple.finder|FXPreferredViewStyle"]=1
  ["com.apple.finder|NewWindowTarget"]=1
  ["com.apple.finder|ShowExternalHardDrivesOnDesktop"]=1
  ["com.apple.finder|ShowRemovableMediaOnDesktop"]=1
  ["NSGlobalDomain|AppleInterfaceStyle"]=1
  ["NSGlobalDomain|AppleShowAllExtensions"]=1
  ["NSGlobalDomain|NSDocumentSaveNewDocumentsToCloud"]=1
  ["com.apple.AppleMultitouchTrackpad|Clicking"]=1
  ["NSGlobalDomain|com.apple.trackpad.scaling"]=1
  ["com.apple.screencapture|style"]=1
  ["com.apple.menuextra.clock|IsAnalog"]=1
  ["com.apple.menuextra.clock|ShowDate"]=1
  ["com.apple.menuextra.clock|ShowDayOfWeek"]=1
  ["com.apple.WindowManager|HideDesktop"]=1
  ["com.apple.Music|userWantsPlaybackNotifications"]=1
)

# Each entry: domain|key|macOS_factory_default|nix_option_path|description
# We check if current value differs from factory default AND is not already managed.
DEFAULTS_TO_SCAN=(
  # ── Dock ────────────────────────────────────────────────────
  "com.apple.dock|autohide-delay|0.5|system.defaults.dock.autohide-delay|Dock: autohide delay (seconds)"
  "com.apple.dock|autohide-time-modifier|0.5|system.defaults.dock.autohide-time-modifier|Dock: autohide animation speed"
  "com.apple.dock|expose-group-apps|0|system.defaults.dock.expose-group-apps|Dock: Mission Control group by app"
  "com.apple.dock|launchanim|1|system.defaults.dock.launchanim|Dock: app launch animation"
  "com.apple.dock|magnification|0|system.defaults.dock.magnification|Dock: magnification"
  "com.apple.dock|largesize|64|system.defaults.dock.largesize|Dock: magnified icon size"
  "com.apple.dock|minimize-to-application|0|system.defaults.dock.minimize-to-application|Dock: minimize to app icon"
  "com.apple.dock|mineffect|genie|system.defaults.dock.mineffect|Dock: minimize effect"
  "com.apple.dock|orientation|bottom|system.defaults.dock.orientation|Dock: position on screen"
  "com.apple.dock|show-process-indicators|1|system.defaults.dock.show-process-indicators|Dock: show running indicators"
  "com.apple.dock|show-recents|1|system.defaults.dock.show-recents|Dock: show recent apps"
  "com.apple.dock|showhidden|0|system.defaults.dock.showhidden|Dock: dim hidden app icons"
  "com.apple.dock|static-only|0|system.defaults.dock.static-only|Dock: show only open apps"
  "com.apple.dock|tilesize|48|system.defaults.dock.tilesize|Dock: icon size"
  "com.apple.dock|wvous-tl-corner|1|system.defaults.dock.wvous-tl-corner|Dock: hot corner top-left"
  "com.apple.dock|wvous-tr-corner|1|system.defaults.dock.wvous-tr-corner|Dock: hot corner top-right"
  "com.apple.dock|wvous-bl-corner|1|system.defaults.dock.wvous-bl-corner|Dock: hot corner bottom-left"
  "com.apple.dock|wvous-br-corner|1|system.defaults.dock.wvous-br-corner|Dock: hot corner bottom-right"

  # ── Finder ──────────────────────────────────────────────────
  "com.apple.finder|FXPreferredViewStyle|icnv|system.defaults.finder.FXPreferredViewStyle|Finder: default view style"
  "com.apple.finder|FXDefaultSearchScope|SCcf|system.defaults.finder.FXDefaultSearchScope|Finder: default search scope"
  "com.apple.finder|NewWindowTarget|PfDe|system.defaults.finder.NewWindowTarget|Finder: new window target"
  "com.apple.finder|NewWindowTargetPath||system.defaults.finder.NewWindowTargetPath|Finder: new window target path"
  "com.apple.finder|ShowPathbar|0|system.defaults.finder.ShowPathbar|Finder: show path bar"
  "com.apple.finder|ShowStatusBar|0|system.defaults.finder.ShowStatusBar|Finder: show status bar"
  "com.apple.finder|_FXShowPosixPathInTitle|0|system.defaults.finder._FXShowPosixPathInTitle|Finder: show POSIX path in title"
  "com.apple.finder|QuitMenuItem|0|system.defaults.finder.QuitMenuItem|Finder: allow Quit menu item"
  "com.apple.finder|ShowExternalHardDrivesOnDesktop|1|system.defaults.finder.ShowExternalHardDrivesOnDesktop|Finder: show external drives on desktop"
  "com.apple.finder|ShowHardDrivesOnDesktop|0|system.defaults.finder.ShowHardDrivesOnDesktop|Finder: show hard drives on desktop"
  "com.apple.finder|ShowMountedServersOnDesktop|0|system.defaults.finder.ShowMountedServersOnDesktop|Finder: show servers on desktop"
  "com.apple.finder|ShowRemovableMediaOnDesktop|1|system.defaults.finder.ShowRemovableMediaOnDesktop|Finder: show removable media on desktop"
  "com.apple.finder|WarnOnEmptyTrash|1|system.defaults.finder.WarnOnEmptyTrash|Finder: warn before emptying trash"
  "com.apple.finder|CreateDesktop|1|system.defaults.finder.CreateDesktop|Finder: show desktop icons"

  # ── NSGlobalDomain ──────────────────────────────────────────
  "NSGlobalDomain|AppleInterfaceStyle||system.defaults.NSGlobalDomain.AppleInterfaceStyle|Global: appearance (Dark/nil)"
  "NSGlobalDomain|AppleInterfaceStyleSwitchesAutomatically|0|system.defaults.NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically|Global: auto switch appearance"
  "NSGlobalDomain|AppleMiniaturizeOnDoubleClick|0|system.defaults.NSGlobalDomain.AppleMiniaturizeOnDoubleClick|Global: double-click titlebar minimizes"
  "NSGlobalDomain|AppleShowAllExtensions|0|system.defaults.NSGlobalDomain.AppleShowAllExtensions|Global: show all file extensions"
  "NSGlobalDomain|AppleShowScrollBars|Automatic|system.defaults.NSGlobalDomain.AppleShowScrollBars|Global: show scroll bars"
  "NSGlobalDomain|AppleScrollerPagingBehavior|0|system.defaults.NSGlobalDomain.AppleScrollerPagingBehavior|Global: click scroll bar jumps to spot"
  "NSGlobalDomain|AppleWindowTabbingMode|fullscreen|system.defaults.NSGlobalDomain.AppleWindowTabbingMode|Global: prefer tabs when opening docs"
  "NSGlobalDomain|InitialKeyRepeat|25|system.defaults.NSGlobalDomain.InitialKeyRepeat|Global: key repeat initial delay"
  "NSGlobalDomain|KeyRepeat|6|system.defaults.NSGlobalDomain.KeyRepeat|Global: key repeat rate"
  "NSGlobalDomain|NSAutomaticCapitalizationEnabled|1|system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled|Global: auto capitalize"
  "NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|1|system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled|Global: smart dashes"
  "NSGlobalDomain|NSAutomaticPeriodSubstitutionEnabled|1|system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled|Global: double-space period"
  "NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|1|system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled|Global: smart quotes"
  "NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled|1|system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled|Global: auto spell correct"
  "NSGlobalDomain|NSNavPanelExpandedStateForSaveMode|0|system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode|Global: expand save panel by default"
  "NSGlobalDomain|NSNavPanelExpandedStateForSaveMode2|0|system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2|Global: expand save panel (secondary)"
  "NSGlobalDomain|NSTableViewDefaultSizeMode|2|system.defaults.NSGlobalDomain.NSTableViewDefaultSizeMode|Global: sidebar icon size"
  "NSGlobalDomain|PMPrintingExpandedStateForPrint|0|system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint|Global: expand print panel by default"
  "NSGlobalDomain|PMPrintingExpandedStateForPrint2|0|system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2|Global: expand print panel (secondary)"
  "NSGlobalDomain|com.apple.swipescrolldirection|1|system.defaults.NSGlobalDomain.\"com.apple.swipescrolldirection\"|Global: natural scroll direction"
  "NSGlobalDomain|ApplePressAndHoldEnabled|1|system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled|Global: press-and-hold for accents (vs key repeat)"
  "NSGlobalDomain|_HIHideMenuBar|0|system.defaults.NSGlobalDomain._HIHideMenuBar|Global: auto-hide menu bar"
  "NSGlobalDomain|AppleICUForce24HourTime|0|system.defaults.NSGlobalDomain.AppleICUForce24HourTime|Global: force 24-hour time"

  # ── Trackpad ────────────────────────────────────────────────
  "com.apple.AppleMultitouchTrackpad|Clicking|0|system.defaults.trackpad.Clicking|Trackpad: tap to click"
  "com.apple.AppleMultitouchTrackpad|TrackpadRightClick|1|system.defaults.trackpad.TrackpadRightClick|Trackpad: two-finger right click"
  "com.apple.AppleMultitouchTrackpad|TrackpadThreeFingerDrag|0|system.defaults.trackpad.TrackpadThreeFingerDrag|Trackpad: three-finger drag"
  "com.apple.AppleMultitouchTrackpad|Dragging|0|system.defaults.trackpad.Dragging|Trackpad: dragging"
  "NSGlobalDomain|com.apple.trackpad.scaling|1|system.defaults.trackpad.scaling|Trackpad: tracking speed"
  "NSGlobalDomain|com.apple.trackpad.forceClick|1|system.defaults.NSGlobalDomain.\"com.apple.trackpad.forceClick\"|Trackpad: force click"

  # ── Screenshot ──────────────────────────────────────────────
  "com.apple.screencapture|disable-shadow|0|system.defaults.screencapture.disable-shadow|Screenshot: disable window shadow"
  "com.apple.screencapture|location||system.defaults.screencapture.location|Screenshot: save location"
  "com.apple.screencapture|show-thumbnail|1|system.defaults.screencapture.show-thumbnail|Screenshot: show floating thumbnail"
  "com.apple.screencapture|style|selection|system.defaults.screencapture.style|Screenshot: capture style"
  "com.apple.screencapture|target|file|system.defaults.screencapture.target|Screenshot: target (file/clipboard)"
  "com.apple.screencapture|type|png|system.defaults.screencapture.type|Screenshot: image format"

  # ── Menu Bar Clock ─────────────────────────────────────────
  "com.apple.menuextra.clock|IsAnalog|0|system.defaults.menuExtraClock.IsAnalog|Clock: analog clock"
  "com.apple.menuextra.clock|ShowAMPM|1|system.defaults.menuExtraClock.ShowAMPM|Clock: show AM/PM"
  "com.apple.menuextra.clock|ShowDate|1|system.defaults.menuExtraClock.ShowDate|Clock: show date"
  "com.apple.menuextra.clock|ShowDayOfWeek|1|system.defaults.menuExtraClock.ShowDayOfWeek|Clock: show day of week"
  "com.apple.menuextra.clock|ShowSeconds|0|system.defaults.menuExtraClock.ShowSeconds|Clock: show seconds"

  # ── Window Manager ─────────────────────────────────────────
  "com.apple.WindowManager|GloballyEnabled|0|system.defaults.WindowManager.GloballyEnabled|Window Manager: Stage Manager"
  "com.apple.WindowManager|HideDesktop|0|system.defaults.WindowManager.HideDesktop|Window Manager: hide desktop in Stage Manager"
  "com.apple.WindowManager|StageManagerHideWidgets|0|system.defaults.WindowManager.StageManagerHideWidgets|Window Manager: hide widgets in Stage Manager"
  "com.apple.WindowManager|StandardHideWidgets|0|system.defaults.WindowManager.StandardHideWidgets|Window Manager: hide widgets on desktop"

  # ── Login Window ────────────────────────────────────────────
  "com.apple.loginwindow|GuestEnabled|1|system.defaults.loginwindow.GuestEnabled|Login: guest account enabled"
  "com.apple.loginwindow|DisableConsoleAccess|0|system.defaults.loginwindow.DisableConsoleAccess|Login: disable console access"
)

UNMANAGED_ITEMS=()

for entry in "${DEFAULTS_TO_SCAN[@]}"; do
  IFS='|' read -r domain key factory nix_path desc <<< "$entry"

  # Skip if already managed in nix config
  if [[ -n "${MANAGED_DEFAULTS["$domain|$key"]+x}" ]]; then
    continue
  fi

  # Read current value
  actual=$(defaults read "$domain" "$key" 2>/dev/null)
  read_ok=$?

  # If the key doesn't exist and factory is empty, both are "unset" — no drift
  if [[ $read_ok -ne 0 && -z "$factory" ]]; then
    continue
  fi

  # If the key doesn't exist but factory is non-empty, the system is at factory — no drift
  if [[ $read_ok -ne 0 ]]; then
    continue
  fi

  # If current matches factory default, no drift
  if [[ "$actual" == "$factory" ]]; then
    continue
  fi

  # This default has been customized but is not in the nix config
  UNMANAGED_ITEMS+=("$desc|$actual|$nix_path|$factory")
  warn "${desc}: ${BOLD}${actual}${NC}${YELLOW} (factory: ${factory:-<unset>})${NC}"
done

if [[ ${#UNMANAGED_ITEMS[@]} -eq 0 ]]; then
  pass "all scanned defaults match factory values or are already managed"
fi

# Print nix snippet for unmanaged defaults
if [[ ${#UNMANAGED_ITEMS[@]} -gt 0 ]]; then
  echo ""
  echo -e "  ${DIM}Add to core/mbp-darwin-core.nix under system.defaults:${NC}"
  echo ""
  for item in "${UNMANAGED_ITEMS[@]}"; do
    IFS='|' read -r desc val nix_path factory_val <<< "$item"
    # Format the value for nix: use factory default type as a hint
    # If factory is a float (contains .), current value is numeric too — keep as number
    if [[ "$factory_val" =~ \. ]] && [[ "$val" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
      nix_val="$val"
    elif [[ "$val" == "1" || "$val" == "0" ]]; then
      # Only treat as boolean if factory default is also 0 or 1
      if [[ "$factory_val" == "0" || "$factory_val" == "1" ]]; then
        if [[ "$val" == "1" ]]; then nix_val="true"; else nix_val="false"; fi
      else
        nix_val="$val"
      fi
    elif [[ "$val" =~ ^-?[0-9]+$ ]]; then
      nix_val="$val"
    elif [[ "$val" =~ ^-?[0-9]*\.[0-9]+$ ]]; then
      nix_val="$val"
    else
      nix_val="\"$val\""
    fi
    echo -e "    ${GREEN}${nix_path} = ${nix_val};${NC}"
  done
fi

# ═════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${PASS} passed${NC} · ${RED}${FAIL} failed${NC} · ${YELLOW}${WARN} warnings${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
echo ""

if [[ $FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
