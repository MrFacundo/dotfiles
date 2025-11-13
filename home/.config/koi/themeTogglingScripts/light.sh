#!/bin/bash

export PATH="$PATH:/home/facu/.spicetify"

KONSOLE_CONFIG="$HOME/.config/konsole"
KONSOLE_RC="$HOME/.config/konsolerc"
PROFILE="Light"
THEME="Leaf Light"
COLOR_SCHEME="Leaf-Light"
LIGHTNESS_MODE=1

# Konsole: Set theme configuration
cp -f "$KONSOLE_CONFIG/konsolerc_light" "$KONSOLE_RC"

# Konsole: Apply profile to all instances
for instance in $(qdbus | grep org.kde.konsole); do
  for session in $(qdbus "$instance" | grep -E '^/Sessions/'); do
    qdbus "$instance" "$session" org.kde.konsole.Session.setProfile "$PROFILE"
  done
done

# Spicetify: Set lightness mode
if command -v spicetify &>/dev/null; then
  spicetify config color_scheme leaf-light
  spicetify apply
fi

# Variety: Set lightness mode and change wallpaper
if command -v variety &>/dev/null; then
  (variety --set-option lightness_mode $LIGHTNESS_MODE >/dev/null 2>&1) &
  sleep 1
  (variety --next >/dev/null 2>&1) &
fi