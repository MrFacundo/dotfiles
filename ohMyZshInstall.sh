#!/bin/bash

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Define directories
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
PLUGIN_DIR="$ZSH_CUSTOM/plugins"
THEME_DIR="$ZSH_CUSTOM/themes"

# Create directories if they don't exist
mkdir -p "$PLUGIN_DIR"
mkdir -p "$THEME_DIR"

# Plugins to be installed
declare -A plugins
plugins=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
  ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
)

# Install plugins
for plugin in "${!plugins[@]}"; do
  if [ ! -d "$PLUGIN_DIR/$plugin" ]; then
    git clone "${plugins[$plugin]}" "$PLUGIN_DIR/$plugin"
    echo "Installed $plugin"
  else
    echo "$plugin is already installed"
  fi
done

# Theme to be installed
theme="powerlevel10k"
theme_url="https://github.com/romkatv/powerlevel10k.git"

# Install theme
if [ ! -d "$THEME_DIR/$theme" ]; then
  git clone --depth=1 "$theme_url" "$THEME_DIR/$theme"
  echo "Installed theme $theme"
else
  echo "Theme $theme is already installed"
fi

# Copy necessary files to the appropriate directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy custom directory
cp -r "$SCRIPT_DIR/custom" "$ZSH_CUSTOM"

# Copy .p10k.zsh and .zshrc to home directory
cp "$SCRIPT_DIR/.p10k.zsh" ~/
cp "$SCRIPT_DIR/.zshrc" ~/

# Print completion message
echo ""
echo "Oh My Zsh has been installed and configured!"
echo "Custom directory, .p10k.zsh, and .zshrc have been copied to the appropriate locations."
echo ""
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply the changes."
