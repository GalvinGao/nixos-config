#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NIX_FILE="/etc/nix-darwin/core/darwin/homebrew.nix"

echo -e "${YELLOW}🍺 Finding missing Homebrew packages${NC}\n"

# Get current installations
INSTALLED_FORMULAE=$(brew list --formula | sort)
INSTALLED_CASKS=$(brew list --cask | sort)

# Extract current brews from nix file
CURRENT_BREWS=$(sed -n '/brews = \[/,/\];/p' "$NIX_FILE" | 
    grep -E '^\s*"[^"]+"\s*$' | 
    sed 's/.*"\(.*\)".*/\1/' | 
    sed 's|.*/||' |
    sort)

# Extract current casks from nix file
CURRENT_CASKS=$(sed -n '/casks = \[/,/\];/p' "$NIX_FILE" | 
    grep -E '^\s*"[^"]+"\s*(#.*)?$' | 
    sed 's/.*"\([^"]*\)".*/\1/' | 
    sort)

# Common dependency patterns
DEPENDENCY_PATTERNS=(
    '^lib' '^ca-certificates$' '^certifi$' '^gettext$' '^ncurses$'
    '^openssl' '^pcre' '^readline$' '^sqlite$' '^xz$' '^zlib$' '^zstd$'
    '^brotli$' '^c-ares$' '^cffi$' '^cryptography$' '^mpdecimal$'
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
    local package="$1"
    for pattern in "${DEPENDENCY_PATTERNS[@]}"; do
        if [[ $package =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Find missing formulae
MISSING_FORMULAE_EXPLICIT=()
while IFS= read -r formula; do
    if ! echo "$CURRENT_BREWS" | grep -q "^${formula}$"; then
        if ! is_likely_dependency "$formula"; then
            MISSING_FORMULAE_EXPLICIT+=("$formula")
        fi
    fi
done <<< "$INSTALLED_FORMULAE"

# Find missing casks
MISSING_CASKS=()
while IFS= read -r cask; do
    if ! echo "$CURRENT_CASKS" | grep -q "^${cask}$"; then
        MISSING_CASKS+=("$cask")
    fi
done <<< "$INSTALLED_CASKS"

# Print results
if [ ${#MISSING_FORMULAE_EXPLICIT[@]} -eq 0 ] && [ ${#MISSING_CASKS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All packages are already in your nix config!${NC}"
    exit 0
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ${#MISSING_FORMULAE_EXPLICIT[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing formulae (${#MISSING_FORMULAE_EXPLICIT[@]}):${NC}"
    echo -e "${GREEN}Add these to the 'brews' array:${NC}\n"
    for formula in "${MISSING_FORMULAE_EXPLICIT[@]}"; do
        echo "      \"$formula\""
    done
fi

if [ ${#MISSING_CASKS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing casks (${#MISSING_CASKS[@]}):${NC}"
    echo -e "${GREEN}Add these to the 'casks' array:${NC}\n"
    for cask in "${MISSING_CASKS[@]}"; do
        echo "      \"$cask\""
    done
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}Instructions:${NC}"
echo "1. Copy the lines above"
echo "2. Open: $NIX_FILE"
echo "3. Paste formulae into the 'brews = [' section"
echo "4. Paste casks into the 'casks = [' section"
echo "5. Run: darwin-rebuild switch --flake /etc/nix-darwin"
