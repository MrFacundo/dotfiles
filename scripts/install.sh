#!/usr/bin/env bash
# Arch / KDE setup. Re-execs itself under zsh once zsh is installed.
#
#   ./scripts/install.sh                  every step, in order
#   ./scripts/install.sh --skip aur       skip a step (repeatable)
#   ./scripts/install.sh --only stow      run one step and stop
#   ./scripts/install.sh --list           show the steps
#
# Every step is idempotent; re-running picks up where it left off.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/packages.sh"

if [ -n "${BASH_VERSION:-}" ]; then
  set -euo pipefail
elif [ -n "${ZSH_VERSION:-}" ]; then
  set -e
  set -u
  setopt PIPE_FAIL >/dev/null 2>&1 || true
else
  set -eu
fi

DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not root: makepkg refuses to run as root" >&2
  echo "and every file it creates in \$HOME would end up owned by root." >&2
  exit 1
fi

preflight() {
  local missing="" c
  for c in git curl python3 sudo; do
    command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
  done
  if [ -n "$missing" ]; then
    echo "==> Installing prerequisites:$missing"
    sudo pacman -S --needed --noconfirm git curl python sudo
  fi
  sudo -v
}

steps=(
  "pacman:install_pacman_packages"
  "yay:install_yay"
  "aur:install_aur_packages"
  "lazyvim:install_lazyvim"
  "kwin:update_kwinrc"
  "firefox:setup_firefox_config"
  "plasmoids:install_plasmoids"
  "stow:run_stow"
  "services:enable_services"
  "gh:gh_auth_login"
)

skip=""
only=""

while [ $# -gt 0 ]; do
  case "$1" in
  --skip)
    [ $# -ge 2 ] || {
      echo "--skip needs a step name" >&2
      exit 1
    }
    skip="$skip $2"
    shift 2
    ;;
  --only)
    [ $# -ge 2 ] || {
      echo "--only needs a step name" >&2
      exit 1
    }
    only="$2"
    shift 2
    ;;
  --list)
    for entry in "${steps[@]}"; do
      printf '%s\t%s\n' "${entry%%:*}" "${entry##*:}"
    done
    exit 0
    ;;
  -h | --help)
    sed -n '2,9p' "$0"
    exit 0
    ;;
  *)
    echo "unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

known_step() {
  local entry
  for entry in "${steps[@]}"; do [ "${entry%%:*}" = "$1" ] && return 0; done
  return 1
}
for name in $skip $only; do
  known_step "$name" || {
    echo "unknown step: $name (see --list)" >&2
    exit 1
  }
done

SCRIPT_PATH="$(readlink -f "$0")"
if [ -z "${ZSH_VERSION:-}" ]; then
  if ! command -v zsh >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zsh
  fi
  RUNZSH=no CHSH=no bash "$DOTFILES_DIR/scripts/ohMyZshInstall.sh" || true
  exec zsh "$SCRIPT_PATH" "$@"
fi

if [ -n "${ZSH_VERSION:-}" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no bash "$DOTFILES_DIR/scripts/ohMyZshInstall.sh" || true
fi

install_pacman_packages() {
  echo "==> Updating system and installing pacman packages (sudo may prompt for password)"
  # A stale keyring makes every signature check fail on a long-unused install.
  sudo pacman -Sy --needed --noconfirm archlinux-keyring ||
    echo "    keyring refresh failed; continuing"

  # pacman aborts the whole transaction over one unknown package.
  local p
  local -a available=() unavailable=()
  for p in "${pacman_pkgs[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then
      available+=("$p")
    else
      unavailable+=("$p")
    fi
  done

  if [ ${#available[@]} -gt 0 ]; then
    sudo pacman -Syu --needed --noconfirm "${available[@]}"
  fi
  if [ ${#unavailable[@]} -gt 0 ]; then
    echo "    not in the official repos, deferred to the AUR step: ${unavailable[*]}"
    aur_pkgs+=("${unavailable[@]}")
  fi
}

install_yay() {
  if ! command -v yay >/dev/null 2>&1; then
    echo "==> Installing yay AUR helper"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir=$(mktemp -d)
    if git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" &&
      (cd "$tmpdir/yay" && makepkg -si --noconfirm); then
      rm -rf "$tmpdir"
    else
      rm -rf "$tmpdir"
      echo "yay build failed; AUR packages will be skipped" >&2
      return 0
    fi
  else
    echo "==> yay already installed"
  fi
}

install_aur_packages() {
  if command -v yay >/dev/null 2>&1; then
    echo "Do you want to install the following AUR packages?"
    for pkg in "${aur_pkgs[@]}"; do
      echo "  - $pkg"
    done
    local aur_choice
    if [ ! -t 0 ]; then
      aur_choice="${INSTALL_AUR:-n}"
      echo "[non-interactive] INSTALL_AUR=$aur_choice"
    else
      printf "[y] install  [N] skip: "
      read -r aur_choice
    fi
    case "$aur_choice" in
    [yY])
      echo "==> Installing AUR packages via yay"
      yay -S --aur --needed --noconfirm --norebuild --noredownload --noansweredit --noanswerdiff --answerclean N "${aur_pkgs[@]}" ||
        echo "Some AUR packages failed to install. You can re-run: yay -S --aur --needed ${aur_pkgs[*]}"
      ;;
    *)
      echo "==> Skipping AUR package installation"
      ;;
    esac
  else
    echo "==> yay not available; skipping AUR installs"
  fi
}

gh_auth_login() {
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      echo "==> gh already authenticated"
      return 0
    fi
    if [ ! -t 0 ]; then
      echo "==> no terminal; run 'gh auth login' by hand afterwards"
      return 0
    fi
    echo "==> Running 'gh auth login' (interactive)"
    gh auth login || true
    printf "After finishing 'gh auth login', press Enter to continue..."
    read -r _
  else
    echo "==> gh (GitHub CLI) not installed; skipping 'gh auth login' step"
  fi
}

install_lazyvim() {
  echo "==> Installing LazyVim starter into ~/.config/nvim"
  # Moving a stowed ~/.config/nvim aside would break its symlinks.
  if [ -f "$HOME/.config/nvim/lua/config/lazy.lua" ]; then
    echo "LazyVim already installed"
    return 0
  fi
  if [ -d "$HOME/.config/nvim" ]; then
    local timestamp
    timestamp=$(date +%s)
    echo "Existing ~/.config/nvim detected; moving to ~/.config/nvim.backup.$timestamp"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$timestamp"
  fi
  if git clone https://github.com/LazyVim/starter.git "$HOME/.config/nvim"; then
    rm -rf "$HOME/.config/nvim/.git"
    echo "LazyVim starter cloned to ~/.config/nvim"
  else
    echo "Failed to clone LazyVim starter. You can try: git clone https://github.com/LazyVim/starter.git ~/.config/nvim"
  fi
}

update_kwinrc() {
  local KWINRC
  KWINRC="$HOME/.config/kwinrc"
  echo "==> Ensuring $KWINRC contains krohnkite settings (backing up first)"
  local timestamp
  timestamp=$(date +%s)
  if [ -f "$KWINRC" ]; then
    cp "$KWINRC" "$KWINRC.backup.$timestamp"
  else
    mkdir -p "$(dirname "$KWINRC")"
    touch "$KWINRC"
  fi
  python3 - "$KWINRC" <<'PY'
import sys
from configparser import ConfigParser
path = sys.argv[1]
# KDE writes duplicate keys and inline '[' in values; strict parsing raises.
cfg = ConfigParser(strict=False, interpolation=None)
# preserve key case
cfg.optionxform = str
try:
    cfg.read(path)
except Exception as exc:
    print(f'could not parse {path}: {exc}')
    print('leaving it alone; the backup beside it is untouched')
    raise SystemExit(0)

sections = {
    'Plugins': {
        'blurEnabled': 'false',
        'diminactiveEnabled': 'true',
        'forceblurEnabled': 'true',
        'krohnkiteEnabled': 'true',
        'slideEnabled': 'false',
    },
    'Script-krohnkite': {
        'screenGapBetween': '10',
        'screenGapBottom': '10',
        'screenGapLeft': '10',
        'screenGapRight': '10',
        'screenGapTop': '10',
    },
    'Windows': {
        'FocusPolicy': 'FocusFollowsMouse',
    }
}

for sec, items in sections.items():
    if not cfg.has_section(sec):
        cfg.add_section(sec)
    for k, v in items.items():
        cfg.set(sec, k, v)

out_path = path + '.tmp'
with open(out_path, 'w') as f:
    for sec in sorted(cfg.sections(), key=lambda s: s.lower()):
        f.write(f"[{sec}]\n")
        for key in cfg[sec]:
            f.write(f"{key}={cfg[sec][key]}\n")
        f.write('\n')

import os
os.replace(out_path, path)
print('kwinrc updated')
PY
}

setup_firefox_config() {
  for BASE in \
    "$HOME/.config/mozilla/firefox" \
    "$HOME/.mozilla/firefox" \
    "$HOME/snap/firefox/common/.mozilla/firefox" \
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"; do
    [ -d "$BASE" ] || continue

    PROFILE=$(find "$BASE" -maxdepth 1 -type d -name "*.default-release" | head -n1)
    [ -z "$PROFILE" ] && PROFILE=$(find "$BASE" -maxdepth 1 -type d -name "*.default" | head -n1)
    [ -z "$PROFILE" ] && continue

    mkdir -p "$HOME/.config"

    DEST="$HOME/.config/firefox"

    if [ -L "$DEST" ]; then
      if [ "$(readlink -f "$DEST")" = "$(readlink -f "$PROFILE")" ]; then
        echo "==> Firefox config symlink already correctly set up"
      else
        mv "$DEST" "${DEST}.backup.$(date +%s)"
        ln -s "$PROFILE" "$DEST"
      fi
    elif [ -e "$DEST" ]; then
      mv "$DEST" "${DEST}.backup.$(date +%s)"
      ln -s "$PROFILE" "$DEST"
    else
      ln -s "$PROFILE" "$DEST"
    fi

    # Enable custom CSS support
    echo "==> Enabling custom CSS in Firefox profile"
    USER_JS="$PROFILE/user.js"
    touch "$USER_JS" # Ensure file exists
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS"; then
      echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >>"$USER_JS"
      echo "Added custom CSS preference to $USER_JS"
    else
      echo "Custom CSS preference already exists in $USER_JS"
    fi

    return 0
  done
  return 0
}

install_plasmoids() {
  # Third-party Plasma widgets the stowed panel layout references; without
  # them the panel comes back with "Widget unable to load" tiles.
  bash "$DOTFILES_DIR/scripts/install-plasmoids.sh" ||
    echo "    widget install failed; re-run: ./scripts/install-plasmoids.sh"
}

run_stow() {
  echo "==> Preparing to run 'stow --no-folding -t $HOME home' from $DOTFILES_DIR"

  BACKUP_DIR="$DOTFILES_DIR/.stow_backups/$(date +%s)"
  mkdir -p "$BACKUP_DIR"

  # Files KDE, LazyVim and zsh create on first run; stow refuses to
  # overwrite them.
  paths=(
    "$HOME/.config/dolphinrc"
    "$HOME/.config/kglobalshortcutsrc"
    "$HOME/.config/kdeglobals"
    "$HOME/.config/kdedefaults/kdeglobals"
    "$HOME/.config/kwinrulesrc"
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    "$HOME/.config/plasmashellrc"
    "$HOME/.config/spectaclerc"
    "$HOME/.config/nvim/lua/config/keymaps.lua"
    "$HOME/.zshrc"
  )

  for p in "${paths[@]}"; do
    [ -e "$p" ] || continue
    # Without a replacement in the repo the file would just disappear.
    if [ ! -e "$DOTFILES_DIR/home${p#$HOME}" ]; then
      echo "Keeping $p (not in the repo)"
      continue
    fi
    dest="$BACKUP_DIR${p#$HOME}"
    mkdir -p "$(dirname "$dest")"
    cp -a "$p" "$dest"
    rm -rf "$p"
    echo "Removed $p (backup saved to $dest)"
  done

  if ! command -v stow >/dev/null 2>&1; then
    echo "stow not found; installing via pacman"
    sudo pacman -S --needed --noconfirm stow
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    IGNORE_ARGS=("--no-folding")
    IGNORE_ARGS+=("--ignore=^\\.config/firefox$")

    (cd "$DOTFILES_DIR" && stow "${IGNORE_ARGS[@]}" -t "$HOME" home) && echo "stow completed successfully" || {
      echo
      echo "WARNING: 'stow' reported conflicts or failed. It did not overwrite any existing files."
      echo "To resolve conflicts manually:"
      echo "  1) Inspect stow's error output above to see which target files conflict."
      echo "  2) For each conflicting file, remove or move the existing file in your home, for example:"
      echo "       rm -rf \"$HOME/.config/some-conflicting-file\""
      echo "     then re-run stow from the dotfiles directory:"
      echo "       (cd \"$DOTFILES_DIR\" && stow --no-folding -t \"$HOME\" home)"
      echo "  or use the linkdot shell function"
    }
  else
    echo "Dotfiles directory $DOTFILES_DIR not found; skipping stow"
  fi
}

# ---------------------------------------------------------------- services
enable_services() {
  echo "==> Services"

  # `systemctl enable` on a missing unit fails the run.
  has_unit() { systemctl list-unit-files --no-legend "$1" 2>/dev/null | grep -q .; }

  local unit
  for unit in bluetooth.service docker.service; do
    if ! has_unit "$unit"; then
      echo "    $unit not installed; skipping"
      continue
    fi
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
      echo "    $unit already enabled"
    else
      sudo systemctl enable --now "$unit" && echo "    enabled $unit" ||
        echo "    could not enable $unit - check: systemctl status $unit"
    fi
  done

  if systemctl --user list-unit-files --no-legend syncthing.service 2>/dev/null | grep -q .; then
    if systemctl --user is-enabled --quiet syncthing.service 2>/dev/null; then
      echo "    syncthing.service (user) already enabled"
    else
      systemctl --user enable --now syncthing.service &&
        echo "    enabled syncthing.service (user)" ||
        echo "    could not enable syncthing.service - check: systemctl --user status syncthing"
    fi
  else
    echo "    syncthing not installed; skipping"
  fi

  if getent group docker >/dev/null 2>&1; then
    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
      echo "    $USER already in the docker group"
    else
      sudo usermod -aG docker "$USER" &&
        echo "    added $USER to the docker group (log out and back in to use it)"
    fi
  fi
}

print_manual_steps() {
  echo "Setup script complete."
  echo "Reboot the system: the docker group membership and the fonts only"
  echo "take effect in a new session."
  echo "==> Manual steps: see README.md \"Extra configurations\" for details"
}

is_skipped() {
  local s
  for s in $skip; do [ "$s" = "$1" ] && return 0; done
  return 1
}

main() {
  preflight
  local entry name fn
  for entry in "${steps[@]}"; do
    name="${entry%%:*}"
    fn="${entry##*:}"
    if [ -n "$only" ] && [ "$only" != "$name" ]; then continue; fi
    if is_skipped "$name"; then
      echo "### skipping $name"
      continue
    fi
    "$fn"
  done
  [ -n "$only" ] || print_manual_steps
}

main "$@"
