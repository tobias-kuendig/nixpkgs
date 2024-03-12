#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=./. -i bash -p curl jq nix-prefetch common-updater-scripts nix coreutils
# shellcheck shell=bash
set -euo pipefail

VERSION=$(curl -s https://api.github.com/repos/facebook/buck2/releases \
  | jq -r 'sort_by(.created_at) | reverse |
           (map
             (select ((.prerelease == true) and (.name != "latest"))) |
             first
           ) | .name')
PRELUDE_HASH=$(curl -sLo - "https://github.com/facebook/buck2/releases/download/${VERSION}/prelude_hash")
PRELUDE_DL_URL="https://github.com/facebook/buck2-prelude/archive/${PRELUDE_HASH}.tar.gz"

echo "Latest buck2 prerelease: $VERSION"
echo "Compatible buck2-prelude hash: $PRELUDE_HASH"

ARCHS=(
    "x86_64-linux:x86_64-unknown-linux-musl"
    "x86_64-darwin:x86_64-apple-darwin"
    "aarch64-linux:aarch64-unknown-linux-musl"
    "aarch64-darwin:aarch64-apple-darwin"
)

NFILE=pkgs/development/tools/build-managers/buck2/default.nix
HFILE=pkgs/development/tools/build-managers/buck2/hashes.json
rm -f "$HFILE" && touch "$HFILE"

PRELUDE_SHA256HASH="$(nix-prefetch-url --type sha256 "$PRELUDE_DL_URL")"
PRELUDE_SRIHASH="$(nix hash to-sri --type sha256 "$PRELUDE_SHA256HASH")"

printf "{ \"_comment\": \"@generated by pkgs/development/tools/build-managers/buck2/update.sh\"\n" >> "$HFILE"
printf ", \"_prelude\": \"$PRELUDE_SRIHASH\"\n" >> "$HFILE"

for arch in "${ARCHS[@]}"; do
    IFS=: read -r arch_name arch_target <<< "$arch"
    sha256hash="$(nix-prefetch-url --type sha256 "https://github.com/facebook/buck2/releases/download/${VERSION}/buck2-${arch_target}.zst")"
    srihash="$(nix hash to-sri --type sha256 "$sha256hash")"
    echo ", \"$arch_name\": \"$srihash\"" >> "$HFILE"
done
echo "}" >> "$HFILE"

sed -i \
  '0,/version\s*=\s*".*";/s//version = "'"$VERSION"'";/' \
  "$NFILE"

sed -i \
  '0,/prelude-hash\s*=\s*".*";/s//prelude-hash = "'"$PRELUDE_HASH"'";/' \
  "$NFILE"

echo "Done; wrote $HFILE and updated version in $NFILE."
