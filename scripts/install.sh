#!/usr/bin/env bash
set -euo pipefail

pacman_pkgs=(7zip bat bc bluez bluez-utils chromium clang cmake cmatrix cowsay docker docker-compose eza fastfetch fd ffmpeg fzf git github-cli gwenview htop jq kcolorchooser kdeconnect ksystemlog ktorrent less libreoffice-fresh man-db man-pages musescore ncdu neovim npm okular poppler qt5-tools ripgrep spectacle starship stow syncthing tree unrar unzip variety vlc yazi zoxide zsh)

aur_pkgs=(koi visual-studio-code-bin stremio slack-desktop spotify ventoy kwin-effects-forceblur kwin-effect-rounded-corners-git webapp-manager)

DOTFILES_DIR="$HOME/dotfiles"

if [ -z "${ZSH_VERSION:-}" ]; then
  if ! command -v zsh >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zsh
  fi
  export AFTER_ZSH=1
  SCRIPT_PATH="$(readlink -f "$0")"
  exec zsh "$SCRIPT_PATH" "$@"
fi

# now running inside zsh
if [ "${AFTER_ZSH:-0}" = "1" ] || [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no bash "$DOTFILES_DIR/scripts/ohMyZshInstall.sh"
fi

install_pacman_packages() {
  echo "==> Updating system and installing pacman packages (sudo may prompt for password)"
  sudo pacman -Syu --needed --noconfirm "${pacman_pkgs[@]}"
}

install_yay() {
  if ! command -v yay >/dev/null 2>&1; then
    echo "==> Installing yay AUR helper"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    pushd "$tmpdir/yay" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf "$tmpdir"
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
    printf "[y] install  [N] skip: "
    read aur_choice
    case "$aur_choice" in
      [yY])
        echo "==> Installing AUR packages via yay"
        yay -S --aur --needed --noconfirm --norebuild --noredownload --noansweredit --noanswerdiff --answerclean N "${aur_pkgs[@]}" || \
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
    echo "==> Running 'gh auth login' (interactive)"
    gh auth login || true
    printf "After finishing 'gh auth login', press Enter to continue..."
    read _
  else
    echo "==> gh (GitHub CLI) not installed; skipping 'gh auth login' step"
  fi
}

install_lazyvim() {
  echo "==> Installing LazyVim starter into ~/.config/nvim"
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

install_krohnkite() {
  if command -v yay >/dev/null 2>&1; then
    echo "==> Installing 'kwin-scripts-krohnkite-git' via yay (keep sources, suppress diffs/edits)"
    yay -S --aur --needed --noconfirm --keepsrc --noanswerdiff --noansweredit kwin-scripts-krohnkite-git || {
      echo "==> yay failed to install kwin-scripts-krohnkite-git"
    }
  else
    echo "==> yay not found; skipping krohnkite AUR install. Install 'yay' to enable this step."
  fi
}

update_kwinrc() {
  # Update ~/.config/kwinrc with krohnkite-related settings
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
  # Use a short Python snippet to set the required sections/keys and write
  # sections sorted alphabetically. This keeps the script concise.
  python3 - "$KWINRC" <<'PY'
import sys
from configparser import ConfigParser
path = sys.argv[1]
cfg = ConfigParser()
# preserve key case
cfg.optionxform = str
cfg.read(path)

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
  echo "==> Setup script finished."
}

setup_firefox_config() {
  for BASE in \
    "$HOME/snap/firefox/common/.mozilla/firefox" \
    "$HOME/.mozilla/firefox" \
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
    touch "$USER_JS"  # Ensure file exists
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS"; then
      echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$USER_JS"
      echo "Added custom CSS preference to $USER_JS"
    else
      echo "Custom CSS preference already exists in $USER_JS"
    fi

    return 0
  done
  return 0
}

run_stow() {
  echo "==> Preparing to run 'stow -t $HOME home' from $DOTFILES_DIR"

  BACKUP_DIR="$DOTFILES_DIR/.stow_backups/$(date +%s)"
  mkdir -p "$BACKUP_DIR"

  paths=(
    "$HOME/.config/dolphinrc"
    "$HOME/.config/kglobalshortcutsrc"
    "$HOME/.config/nvim/lua/config/keymaps.lua"
    "$HOME/.zshrc"
  )

  for p in "${paths[@]}"; do
    if [ -e "$p" ]; then
      dest="$BACKUP_DIR${p#$HOME}"
      mkdir -p "$(dirname "$dest")"
      cp -a "$p" "$dest"
      rm -rf "$p"
      echo "Removed $p (backup saved to $dest)"
    fi
  done

  if ! command -v stow >/dev/null 2>&1; then
    echo "stow not found; installing via pacman"
    sudo pacman -S --needed --noconfirm stow
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    IGNORE_ARGS=()
    # If user has an existing real firefox config dir (not a symlink to our dotfiles),
    # skip stowing the firefox folder to avoid ownership conflicts.
    if [ -d "$HOME/.config/firefox" ] && [ ! -L "$HOME/.config/firefox" ]; then
      echo "==> Detected existing ~/.config/firefox (not a symlink). Skipping firefox when running stow to avoid conflicts."
      IGNORE_ARGS+=(--ignore 'firefox')
    fi

    (cd "$DOTFILES_DIR" && stow "${IGNORE_ARGS[@]}" -t "$HOME" home) && echo "stow completed successfully" || {
      echo
      echo "WARNING: 'stow' reported conflicts or failed. It did not overwrite any existing files."
      echo "To resolve conflicts manually:"
      echo "  1) Inspect stow's error output above to see which target files conflict."
      echo "  2) For each conflicting file, remove or move the existing file in your home, for example:"
      echo "       rm -rf \"$HOME/.config/some-conflicting-file\""
      echo "     then re-run stow from the dotfiles directory:"
      echo "       (cd \"$DOTFILES_DIR\" && stow -t \"$HOME\" home)"
      echo "  or use the linkdot shell function"
    }
  else
    echo "Dotfiles directory $DOTFILES_DIR not found; skipping stow"
  fi
}

print_manual_steps() {
  echo "Setup script complete."
  echo "Reboot the system to ensure all changes take effect."
  echo "==> Manual steps — see README.md for details:"
  echo "  - VSCode Custom CSS extension permissions"
  echo "  - Spicetify"
  echo
  echo "See README.md in the repository root for step-by-step instructions for each item."
}

main() {
  install_pacman_packages
  install_yay
  install_aur_packages
  install_lazyvim
  install_krohnkite
  update_kwinrc
  setup_firefox_config
  run_stow
  print_manual_steps
} 

main "$@"
