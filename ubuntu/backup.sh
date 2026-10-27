#!/usr/bin/env bash
# Phase 0, run on the OLD machine.
# Collects everything in backup-manifest.txt plus Firefox bookmarks into a
# single gpg-encrypted archive for the pendrive.
#
#   ./backup.sh [-o OUTPUT_DIR] [--no-encrypt]
#
# Nothing here is ever tracked by git.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/backup-manifest.txt"

OUT_DIR="$PWD"
ENCRYPT=1

while [ $# -gt 0 ]; do
  case "$1" in
  -o | --output)
    OUT_DIR="$2"
    shift 2
    ;;
  --no-encrypt)
    ENCRYPT=0
    shift
    ;;
  -h | --help)
    sed -n '2,10p' "$0"
    exit 0
    ;;
  *)
    echo "unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

[ -f "$MANIFEST" ] || {
  echo "manifest not found: $MANIFEST" >&2
  exit 1
}

STAMP="$(date +%Y%m%d)"
NAME="csw-backup-$STAMP"
STAGE="$(mktemp -d)"
ROOT="$STAGE/$NAME"
mkdir -p "$ROOT"
trap 'rm -rf "$STAGE"' EXIT

missing=()
excludes=()

echo "==> Collecting manifest entries"
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$line" ] || continue

  if [ "${line:0:1}" = "!" ]; then
    excludes+=("${line:1}")
    continue
  fi

  if [[ "$line" == *"=>"* ]]; then
    src="$(echo "${line%%=>*}" | sed -e 's/[[:space:]]*$//')"
    dest="$(echo "${line##*=>}" | sed -e 's/^[[:space:]]*//')"
  else
    src="$line"
    dest="$line"
  fi

  if [ ! -e "$HOME/$src" ]; then
    missing+=("$src")
    continue
  fi

  mkdir -p "$ROOT/$(dirname "$dest")"
  cp -a "$HOME/$src" "$ROOT/$dest"
  echo "    $src -> $dest"
done <"$MANIFEST"

if [ ${#excludes[@]} -gt 0 ]; then
  echo "==> Dropping excluded paths"
  for ex in "${excludes[@]}"; do
    if [ -e "$ROOT/$ex" ]; then
      rm -rf "${ROOT:?}/$ex"
      echo "    $ex"
    fi
  done
fi

echo "==> Exporting Firefox bookmarks"
export_bookmarks() {
  local profile places out
  for base in "$HOME/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox"; do
    [ -d "$base" ] || continue
    profile=$(find "$base" -maxdepth 1 -type d -name '*.default-release' | head -n1)
    [ -n "$profile" ] || profile=$(find "$base" -maxdepth 1 -type d -name '*.default' | head -n1)
    [ -n "$profile" ] || continue

    places="$profile/places.sqlite"
    [ -f "$places" ] || continue

    cp "$places" "$STAGE/places.sqlite"
    out="$ROOT/firefox/bookmarks.html"
    mkdir -p "$(dirname "$out")"

    if python3 "$SCRIPT_DIR/export-bookmarks.py" "$STAGE/places.sqlite" "$out"; then
      echo "    bookmarks.html written from $(basename "$profile")"
    else
      echo "    bookmark export failed; falling back to bookmarkbackups"
    fi

    # jsonlz4 snapshots as a fallback Firefox can restore natively
    if [ -d "$profile/bookmarkbackups" ]; then
      mkdir -p "$ROOT/firefox/bookmarkbackups"
      cp -a "$profile/bookmarkbackups/." "$ROOT/firefox/bookmarkbackups/"
    fi
    return 0
  done
  echo "    no Firefox profile found"
  return 0
}
export_bookmarks

echo "==> Writing archive"
mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/$NAME.tar.zst"

if [ "$ENCRYPT" -eq 1 ]; then
  # tar streams straight into gpg, so the plaintext never touches the disk and
  # a failed or cancelled passphrase prompt leaves nothing behind. gpg asks
  # before compression starts, not after.
  FINAL="$TARBALL.gpg"
  export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null || true)}"
  echo "==> Encrypting (symmetric gpg; answer the passphrase prompt now)"
  if ! tar -C "$STAGE" -I 'zstd -19 -T0' -cf - "$NAME" |
    gpg --symmetric --cipher-algo AES256 --yes --output "$FINAL"; then
    rm -f "$FINAL"
    echo "    encryption failed - nothing written to $OUT_DIR" >&2
    exit 1
  fi
else
  tar -C "$STAGE" -I 'zstd -19 -T0' -cf "$TARBALL" "$NAME"
  FINAL="$TARBALL"
fi

sha256sum "$FINAL" >"$FINAL.sha256"

echo
echo "Archive:  $FINAL"
echo "Checksum: $FINAL.sha256"
if [ ${#missing[@]} -gt 0 ]; then
  echo
  echo "Not found, skipped:"
  printf '  %s\n' "${missing[@]}"
fi
echo
echo "Copy both files to the pendrive, then verify with:"
echo "  sha256sum -c $(basename "$FINAL").sha256"
