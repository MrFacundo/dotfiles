#!/bin/bash
# Oh My Zsh, its plugins and the Nerd Fonts. Safe to re-run.
#
# RUNZSH=no keeps the installer from dropping into a new shell and stalling
# install.sh; CHSH=no leaves the login shell alone (install.sh re-execs zsh
# itself). Both can be overridden from the environment.

set -euo pipefail

for cmd in curl git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd is required" >&2
    exit 1
  }
done

export RUNZSH="${RUNZSH:-no}"
export CHSH="${CHSH:-no}"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
PLUGIN_DIR="$ZSH_CUSTOM/plugins"
mkdir -p "$PLUGIN_DIR"

declare -A plugins
plugins=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
  ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
)

for plugin in "${!plugins[@]}"; do
  if [ ! -d "$PLUGIN_DIR/$plugin" ]; then
    git clone "${plugins[$plugin]}" "$PLUGIN_DIR/$plugin"
    echo "Installed $plugin"
  else
    echo "$plugin is already installed"
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_SRC="$SCRIPT_DIR/../fonts"
FONT_DIR="$HOME/.local/share/fonts"

if [ -d "$FONT_SRC" ] && [ -n "$(ls -A "$FONT_SRC" 2>/dev/null)" ]; then
  mkdir -p "$FONT_DIR"
  # -u: only copy fonts that are new or newer, so re-runs are cheap.
  cp -u "$FONT_SRC"/* "$FONT_DIR"/
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR" >/dev/null
    echo "Fonts installed and the font cache refreshed"
  else
    echo "fc-cache not found; fonts copied but the cache was not refreshed"
  fi
else
  echo "No fonts directory at $FONT_SRC; skipping fonts"
fi

echo "Oh My Zsh has been installed and configured"
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply the changes."
