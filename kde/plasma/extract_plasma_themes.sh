#!/usr/bin/env bash
set -euo pipefail

# Minimal extractor: find archives directly in ~/.local/share/plasma and
# extract each into a sibling directory with the archive's base name.

SRC="$HOME/.local/share/plasma"
[ -d "$SRC" ] || { echo "Source not found: $SRC" >&2; exit 1; }

shopt -s nullglob
cd "$SRC"

for f in *.zip *.plasmatheme *.tar *.tar.gz *.tgz *.tar.xz *.txz *.tar.bz2 *.tbz2 *.tar.zst; do
  [[ -f "$f" ]] || continue
  base="$f"
  base="${base%.tar.gz}"
  base="${base%.tar.bz2}"
  base="${base%.tar.xz}"
  base="${base%.tar.zst}"
  base="${base%.tgz}"
  base="${base%.tbz2}"
  base="${base%.txz}"
  base="${base%.zip}"
  base="${base%.plasmatheme}"
  dest="$SRC/$base"
  rm -rf "$dest"
  mkdir -p "$dest"
  case "$f" in
    *.zip|*.plasmatheme)
      unzip -q "$f" -d "$dest" ;;
    *)
      tar -xf "$f" -C "$dest" ;;
  esac
done

exit 0
