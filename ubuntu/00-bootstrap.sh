#!/usr/bin/env bash
# Phase 2 - minimum viable system: updates, core tools, dotfiles clone,
# hostname check.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/MrFacundo/dotfiles.git"

echo "==> Updating the system"
sudo apt-get update
sudo apt-get -y full-upgrade

echo "==> Installing core tools"
sudo apt-get install -y git curl wget zsh stow build-essential ca-certificates gnupg

echo "==> Checking hostname"
SERIAL="$(sudo dmidecode -s system-serial-number 2>/dev/null | tr -d '[:space:]')"
EXPECTED="LPT-${SERIAL}-LX"
CURRENT="$(hostnamectl --static)"

if [ -z "$SERIAL" ]; then
  echo "  could not read the serial number; set the hostname by hand"
elif [ "$CURRENT" = "$EXPECTED" ]; then
  echo "  hostname is already $EXPECTED"
else
  echo "  current:  $CURRENT"
  echo "  expected: $EXPECTED"
  printf "  set it now? [y/N]: "
  read -r reply
  if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
    sudo hostnamectl set-hostname "$EXPECTED"
    sudo sed -i "s/\b$CURRENT\b/$EXPECTED/g" /etc/hosts
    echo "  hostname set to $EXPECTED"
  fi
fi

echo "==> Checking username"
echo "  current user: $USER"
echo "  this must match the AD UPN prefix (e.g. fd-troitero)."
echo "  if it does not, see ubuntu/README.md - it is easier to reinstall"
echo "  than to rename a logged-in user."

echo "==> Cloning dotfiles"
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "  $DOTFILES_DIR already exists"
else
  git clone "$REPO_URL" "$DOTFILES_DIR"
  echo "  cloned to $DOTFILES_DIR"
  echo "  (remote is HTTPS; 30-configure.sh switches it to SSH once keys are restored)"
fi

echo
echo "Bootstrap done. Next: 10-compliance.sh"
