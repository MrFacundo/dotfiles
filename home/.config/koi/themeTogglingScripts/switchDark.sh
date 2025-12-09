#!/bin/bash

LIGHTNESS_MODE=0

# Variety: set lightness mode and change wallpaper
if command -v variety >/dev/null 2>&1; then
  (variety --set-option lightness_mode "$LIGHTNESS_MODE" >/dev/null 2>&1) &
  sleep 1
  (variety --next >/dev/null 2>&1) &
fi

exit 0
