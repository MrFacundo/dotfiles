#!/bin/bash

KONSOLE_CONFIG="$HOME/.config/konsole"
KONSOLE_RC="$HOME/.config/konsolerc"

PROFILE="Dark"
KONSOLE_SRC="konsolerc_dark"
LIGHTNESS_MODE=0

# Konsole: Set theme configuration file
if [ -f "$KONSOLE_CONFIG/$KONSOLE_SRC" ]; then
  cp -f "$KONSOLE_CONFIG/$KONSOLE_SRC" "$KONSOLE_RC"
fi

# Konsole: Apply profile to all running instances/sessions
if command -v qdbus >/dev/null 2>&1; then
  qdbus | grep org.kde.konsole 2>/dev/null | while read -r instance; do
    qdbus "$instance" | grep -E '^/Sessions/' 2>/dev/null | while read -r session; do
      qdbus "$instance" "$session" org.kde.konsole.Session.setProfile "$PROFILE" >/dev/null 2>&1 || true
    done
  done
fi

# Variety: set lightness mode and change wallpaper
if command -v variety >/dev/null 2>&1; then
  (variety --set-option lightness_mode "$LIGHTNESS_MODE" >/dev/null 2>&1) &
  sleep 1
  (variety --next >/dev/null 2>&1) &
fi

exit 0
