#!/usr/bin/env bash
# Registers the git filters .gitattributes refers to. Filter definitions live
# in .git/config, which is per clone, so this runs on every machine (the
# install scripts call it before stowing). Idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"
FILTER="scripts/kde-config-filter.py"
APPLETS="home/.config/plasma-org.kde.plasma.desktop-appletsrc"

git -C "$DOTFILES_DIR" config filter.kde-shortcuts.clean "$FILTER shortcuts-clean"
git -C "$DOTFILES_DIR" config filter.kde-applets.clean "$FILTER applets-clean"
git -C "$DOTFILES_DIR" config filter.kde-applets.smudge "$FILTER applets-smudge"

# A clone made before the filters were registered holds the literal @HOME@
# placeholder; check the file out again so the smudge filter expands it.
if grep -q '@HOME@/' "$DOTFILES_DIR/$APPLETS" 2>/dev/null; then
  rm -f "$DOTFILES_DIR/$APPLETS"
  git -C "$DOTFILES_DIR" checkout -- "$APPLETS"
fi

echo "git filters registered in $DOTFILES_DIR"
