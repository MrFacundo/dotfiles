#!/bin/bash

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

for font in "$SCRIPT_DIR/../fonts"/*; do
  cp "$font" "$FONT_DIR"
done

fc-cache -f -v

echo "Fonts have been installed and the font cache has been refreshed"
echo "Oh My Zsh has been installed and configured"
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply the changes."
