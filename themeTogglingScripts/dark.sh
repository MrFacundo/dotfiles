#!/bin/bash

# Variety lightness mode
# Set lightness mode to 0 (dark)
(variety --set-option lightness_mode 0 >/dev/null 2>&1) &
(variety --next >/dev/null 2>&1) &

# Konsole set Leaf Dark theme
cp -f "$HOME/.config/konsole/konsolerc_dark" "$HOME/.config/konsolerc"

# Update kwriterc to use Leaf Dark theme
sed -i 's/^Color Theme=.*/Color Theme=Leaf Dark/' "$HOME/.config/kwriterc"
sed -i 's/^ColorScheme=.*/ColorScheme=Leaf-Dark/' "$HOME/.config/kwriterc"