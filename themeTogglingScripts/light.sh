#!/bin/bash

# Varierty lightness mode
# Set lightness mode to 1 (light)
variety --set-option lightness_mode 1
variety --next

# Konsole set Leaf Light theme
cp -f "$HOME/.config/konsole/konsolerc_light" "$HOME/.config/konsolerc"