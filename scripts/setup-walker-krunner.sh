#!/usr/bin/env bash
# Set up walker (+ elephant) as the KRunner replacement on Arch + KDE Plasma (Wayland).
# Usage: setup-walker-krunner.sh            install / repair (idempotent)
#        setup-walker-krunner.sh --uninstall restore KRunner
# Docs:  scripts/walker-krunner.md
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHIM="$DOTFILES/scripts/walker-krunner.py"
DBUS_SVC_DIR="$HOME/.local/share/dbus-1/services"
UNIT_DIR="$HOME/.config/systemd/user"

PACMAN_PKGS=(wl-clipboard ydotool python-dbus python-gobject libqalculate fd)
AUR_PKGS=(walker-bin elephant elephant-desktopapplications elephant-calc
          elephant-symbols elephant-files elephant-runner elephant-providerlist)

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }

# link SRC DEST: symlink, backing up an existing real file/dir
link() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    warn "backed up existing $dest"
  fi
  ln -sfn "$src" "$dest"
  log "linked $dest -> $src"
}

reload_dbus() {
  busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig >/dev/null
}

uninstall() {
  log "restoring KRunner"
  rm -f "$DBUS_SVC_DIR/org.kde.krunner.service"
  systemctl --user unmask plasma-krunner.service
  pkill -f '[w]alker-krunner.py' || true
  reload_dbus
  log "done; log out and back in to finish"
  exit 0
}

[ "${1:-}" = "--uninstall" ] && uninstall

# 1. packages ---------------------------------------------------------------
command -v yay >/dev/null || { echo "yay is required" >&2; exit 1; }
log "installing packages"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# elephant plugins load only when built with the same Go version as elephant
go_of() { go version "$1" 2>/dev/null | awk '{print $2}'; }
core_go=$(go_of /usr/bin/elephant)
for so in /usr/lib/elephant/*.so; do
  if [ "$(go_of "$so")" != "$core_go" ]; then
    log "Go version mismatch ($so); rebuilding elephant and providers"
    yay -S --rebuild --noconfirm elephant "${AUR_PKGS[@]:2}"
    break
  fi
done

# 2. config links -----------------------------------------------------------
link "$DOTFILES/home/.config/walker" "$HOME/.config/walker"
link "$DOTFILES/home/.config/systemd/user/walker.service" "$UNIT_DIR/walker.service"
link "$DOTFILES/home/.local/share/dbus-1/services/org.kde.krunner.service" \
     "$DBUS_SVC_DIR/org.kde.krunner.service"
chmod +x "$SHIM"

# the D-Bus service file holds an absolute path; keep it pointing at this checkout
svc="$DOTFILES/home/.local/share/dbus-1/services/org.kde.krunner.service"
if ! grep -qx "Exec=$SHIM" "$svc"; then
  sed -i "s|^Exec=.*|Exec=$SHIM|" "$svc"
  log "updated Exec path in $svc"
fi

# 3. services ---------------------------------------------------------------
log "configuring user services"
[ -f "$UNIT_DIR/elephant.service" ] || elephant service enable
systemctl --user daemon-reload
systemctl --user enable --now elephant.service walker.service ydotool.service
systemctl --user restart elephant.service

# 4. replace KRunner --------------------------------------------------------
log "replacing KRunner"
systemctl --user mask plasma-krunner.service
systemctl --user stop plasma-krunner.service 2>/dev/null || true
pkill -x krunner || true
pkill -f '[w]alker-krunner.py' || true
reload_dbus
busctl --user call org.kde.krunner /App org.freedesktop.DBus.Peer Ping >/dev/null

# 5. checks -----------------------------------------------------------------
[ -w /dev/uinput ] || warn "/dev/uinput is read-only for $USER: ydotool cannot paste early keystrokes"
providers=$(elephant listproviders 2>/dev/null | wc -l)
[ "$providers" -gt 0 ] || warn "elephant reports no providers: check 'journalctl --user -u elephant'"
log "done: $providers elephant providers loaded; type on an empty desktop to test"
