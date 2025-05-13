#!/bin/bash

KONSOLE_CONFIG="$HOME/.config/konsole"
KONSOLE_RC="$HOME/.config/konsolerc"
KWRITE_RC="$HOME/.config/kwriterc"
PROFILE="Dark"
THEME="Leaf Dark"
COLOR_SCHEME="Leaf-Dark"
LIGHTNESS_MODE=0

# Konsole: Set theme configuration
cp -f "$KONSOLE_CONFIG/konsolerc_dark" "$KONSOLE_RC"

# Konsole: Apply profile to all instances
for instance in $(qdbus | grep org.kde.konsole); do
  for session in $(qdbus "$instance" | grep -E '^/Sessions/'); do
    qdbus "$instance" "$session" org.kde.konsole.Session.setProfile "$PROFILE"
  done
done

# KWrite: Update theme configuration
sed -i "s/^Color Theme=.*/Color Theme=$THEME/" "$KWRITE_RC"
sed -i "s/^ColorScheme=.*/ColorScheme=$COLOR_SCHEME/" "$KWRITE_RC"

# Variety: Set lightness mode and change wallpaper
(variety --set-option lightness_mode $LIGHTNESS_MODE >/dev/null 2>&1) &
sleep 1
(variety --next >/dev/null 2>&1) &