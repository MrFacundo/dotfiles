#!/bin/bash

# Variety lightness mode
# Set lightness mode to 1 (light)
(variety --set-option lightness_mode 1 >/dev/null 2>&1) &
(variety --next >/dev/null 2>&1) &

# Konsole set Leaf Light theme
cp -f "$HOME/.config/konsole/konsolerc_light" "$HOME/.config/konsolerc"

# Set Leaf Light profile for all Konsole instances

PROFILE="Light"

for instance in $(qdbus | grep org.kde.konsole); do
  for session in $(qdbus "$instance" | grep -E '^/Sessions/'); do
    qdbus "$instance" "$session" org.kde.konsole.Session.setProfile "$PROFILE"
  done
done

# Update kwriterc to use Leaf Light theme
sed -i 's/^Color Theme=.*/Color Theme=Leaf Light/' "$HOME/.config/kwriterc"
sed -i 's/^ColorScheme=.*/ColorScheme=Leaf-Light/' "$HOME/.config/kwriterc"