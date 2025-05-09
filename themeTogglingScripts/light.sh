#!/bin/bash

# Variety lightness mode
# Set lightness mode to 1 (light)
variety --set-option lightness_mode 1
variety --next

# Konsole set Leaf Light theme
cp -f "$HOME/.config/konsole/konsolerc_light" "$HOME/.config/konsolerc"

# Update kwriterc to use Leaf Light theme
sed -i 's/^Color Theme=.*/Color Theme=Leaf Light/' "$HOME/.config/kwriterc"
sed -i 's/^ColorScheme=.*/ColorScheme=Leaf-Light/' "$HOME/.config/kwriterc"