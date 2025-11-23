
KDEGLOBALS="$HOME/.config/kdeglobals"
KONSOLE_CONFIG="$HOME/.config/konsole"
KONSOLE_RC="$HOME/.config/konsolerc"

cs="$(grep -E '^ColorScheme=' "$KDEGLOBALS" 2>/dev/null | cut -d= -f2 || true)"

case "$cs" in
  LeafLight)
    PROFILE="Dark"
    KONSOLE_SRC="konsolerc_dark"
    SPICETIFY_SCHEME="leaf-dark"
    LIGHTNESS_MODE=0
    ;;
  LeafDark)
    PROFILE="Light"
    KONSOLE_SRC="konsolerc_light"
    SPICETIFY_SCHEME="leaf-light"
    LIGHTNESS_MODE=1
    ;;
  *)
    echo "Unrecognized ColorScheme: '${cs:-<empty>}'" >&2
    exit 1
    ;;
esac

# Konsole: Set theme configuration file
if [ -f "$KONSOLE_CONFIG/$KONSOLE_SRC" ]; then
  cp -f "$KONSOLE_CONFIG/$KONSOLE_SRC" "$KONSOLE_RC"
fi

# Konsole: Apply profile to all running instances/sessions
if command -v qdbus &>/dev/null; then
  qdbus | grep org.kde.konsole 2>/dev/null | while read -r instance; do
    qdbus "$instance" | grep -E '^/Sessions/' 2>/dev/null | while read -r session; do
      qdbus "$instance" "$session" org.kde.konsole.Session.setProfile "$PROFILE" >/dev/null 2>&1 || true
    done
  done
fi

# Spicetify: set color scheme and apply
if command -v spicetify &>/dev/null; then
  spicetify config color_scheme "$SPICETIFY_SCHEME" >/dev/null 2>&1 || true
  spicetify apply >/dev/null 2>&1 || true
fi

# Variety: set lightness mode and change wallpaper
if command -v variety &>/dev/null; then
  (variety --set-option lightness_mode "$LIGHTNESS_MODE" >/dev/null 2>&1) &
  sleep 1
  (variety --next >/dev/null 2>&1) &
fi

exit 0