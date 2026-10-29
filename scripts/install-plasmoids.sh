#!/usr/bin/env bash
# Installs the third-party Plasma widgets the stowed panel layout depends on.
#
#   ./scripts/install-plasmoids.sh            install or upgrade to the pinned tags
#   ./scripts/install-plasmoids.sh --force    reinstall even when the version matches
#
# Called by scripts/install.sh (Arch) and ubuntu/30-configure.sh (Neon).
#
# A widget is just a directory under ~/.local/share/plasma/plasmoids/, so this
# is not stowed: kpackagetool6 deletes and re-extracts that directory on every
# upgrade, which would replace the stow symlinks with real files.
#
# The tags are pinned on purpose. home/.config/plasma-org.kde.plasma.desktop-appletsrc
# stores each widget's settings by config key; a widget that renames a key
# upstream comes back with its defaults.
#
# To bump one, check the newest tag first - these repos do not sort
# lexicographically (v3.14 is newer than v3.6):
#   git ls-remote --tags --refs --sort=-v:refname https://github.com/<repo> | head -3

set -euo pipefail

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# repo | tag | package id
widgets=(
  "tilorenz/compact_pager|v3.14|com.github.tilorenz.compact_pager"
  "antroids/application-title-bar|v0.10.0|com.github.antroids.application-title-bar"
  "luisbocanegra/plasma-panel-colorizer|v8.0.0|luisbocanegra.panel.colorizer"
)

PLASMOID_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
tmp=""

installed_version() {
  python3 - "$1/metadata.json" <<'PY' 2>/dev/null || true
import json, sys
try:
    with open(sys.argv[1]) as fh:
        print(json.load(fh)["KPlugin"]["Version"])
except Exception:
    pass
PY
}

main() {
  echo "==> Plasma widgets"

  if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "    kpackagetool6 not found; skipping (install plasma-sdk or plasma-workspace)"
    return 0
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "${tmp:-}"' EXIT

  local entry repo tag id want have pkgdir action
  for entry in "${widgets[@]}"; do
    IFS='|' read -r repo tag id <<<"$entry"
    want="${tag#v}"

    if [ -d "$PLASMOID_DIR/$id" ]; then
      have="$(installed_version "$PLASMOID_DIR/$id")"
      if [ "$FORCE" -eq 0 ] && [ "$have" = "$want" ]; then
        echo "    $id $have already installed"
        continue
      fi
      action="--upgrade"
    else
      have=""
      action="--install"
    fi

    echo "    fetching $repo $tag"
    if ! git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$tag" "https://github.com/$repo" "$tmp/$id"; then
      echo "    clone failed: $repo $tag; skipping"
      continue
    fi

    # Every one of these keeps the plasmoid under package/, but do not rely on it.
    pkgdir="$tmp/$id/package"
    if [ ! -f "$pkgdir/metadata.json" ]; then
      pkgdir="$(dirname "$(find "$tmp/$id" -name metadata.json -print -quit)")"
    fi
    if [ ! -f "$pkgdir/metadata.json" ]; then
      echo "    no metadata.json in $repo; skipping"
      continue
    fi

    if kpackagetool6 --type Plasma/Applet "$action" "$pkgdir" >/dev/null; then
      echo "    ${have:+$have -> }$want $id"
    else
      echo "    kpackagetool6 $action failed for $id"
    fi
  done

  echo "    restart plasmashell to pick up changes: kquitapp6 plasmashell && kstart plasmashell"
}

main "$@"
