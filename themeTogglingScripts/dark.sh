#!/bin/bash

# Varierty lightness mode
# Set lightness mode to 1 (light)
variety --set-option lightness_mode 0
variety --next

# Konsole set Leaf Dark theme
cp -f "$HOME/.config/konsole/konsolerc_dark" "$HOME/.config/konsolerc"