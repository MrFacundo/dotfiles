#!/usr/bin/env bash
# Phase 0, run on the OLD machine, once.
#
# Moves configs that belong in the repo (general, non-secret, non-machine-
# specific) into dotfiles/home/ and replaces them with stow symlinks.
# Secrets and laptop-specific files are NOT handled here - see backup.sh.
#
#   ./track-configs.sh [--dry-run]
#
# The repo is public. Anything moved here ends up on GitHub.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
HOME_DIR="$DOTFILES_DIR/home"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Paths relative to $HOME, moved into dotfiles/home/ at the same relative path.
paths=(
    # AI tooling
    .agents/skills
    .claude/settings.json
    .claude/CLAUDE.md
    .claude/plugins/installed_plugins.json
    .claude/plugins/known_marketplaces.json
    .gemini/settings.json
    .copilot/mcp-config.json
    .copilot/permissions-config.json
    .copilot/copilot-instructions.md

    # shell
    .zshenv
    .zprofile
    .config/git/ignore

    # KDE
    .config/kdeglobals
    .config/plasma-org.kde.plasma.desktop-appletsrc
    .config/panel-colorizer
    .config/spectaclerc
    .config/khotkeysrc
    .local/share/color-schemes

    # apps
    .config/cava
    .config/lazygit
    .config/mpv
    .config/yt-dlp
    .config/spicetify

    # input
    .config/input-remapper-2
)

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    would: $*"
  else
    "$@"
  fi
}

echo "==> Moving configs into $HOME_DIR"
for p in "${paths[@]}"; do
  src="$HOME/$p"
  dest="$HOME_DIR/$p"

  if [ -L "$src" ]; then
    echo "  [skip] $p (already a symlink)"
    continue
  fi
  if [ ! -e "$src" ]; then
    echo "  [skip] $p (not present)"
    continue
  fi
  if [ -e "$dest" ]; then
    echo "  [skip] $p (already in repo)"
    continue
  fi

  echo "  [move] $p"
  run mkdir -p "$(dirname "$dest")"
  run mv "$src" "$dest"
done

echo
echo "==> Scanning the moved files for anything that must not be public"
PATTERN='(api[_-]?key|secret|token|passwd|password|BEGIN [A-Z ]*PRIVATE KEY|bearer|criticalsoftware|iter\.org|codac)'
if [ "$DRY_RUN" -eq 0 ]; then
  hits=$(grep -rIniE "$PATTERN" "$HOME_DIR" --exclude-dir=.git 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "  REVIEW THESE BEFORE COMMITTING:"
    echo "$hits" | sed 's|^|    |'
  else
    echo "  nothing flagged"
  fi
fi

echo
echo "==> Re-running stow"
if [ "$DRY_RUN" -eq 0 ]; then
  (cd "$DOTFILES_DIR" && stow --ignore='^\.config/firefox$' -t "$HOME" home) &&
    echo "  stow completed" ||
    echo "  stow reported conflicts - resolve them, then re-run: stow -t \$HOME home"
fi

echo
echo "Next:"
echo "  1. Review the grep output above and the git diff."
echo "  2. Update the 'Stowed configs' list in README.md."
echo "  3. git add -A && git commit && git push"
