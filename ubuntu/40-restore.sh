#!/usr/bin/env bash
# Phase 6 - restore from the pendrive archive.
#
#   ./40-restore.sh /media/<user>/<pendrive>/csw-backup-YYYYMMDD.tar.zst.gpg
#
# Automatic: unpack, copy manifest entries to their destinations, fix
# permissions on ~/.ssh and ~/.gnupg.
# Everything else is a printed checklist - restoring it is a manual decision.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/backup-manifest.txt"

ARCHIVE="${1:-}"
if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "usage: $0 <archive.tar.zst[.gpg]>" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ -f "$ARCHIVE.sha256" ]; then
  echo "==> Verifying checksum"
  # Compare hashes only: the .sha256 file may name the archive by the path it
  # had on the old machine.
  expected="$(awk '{print $1; exit}' "$ARCHIVE.sha256")"
  actual="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
  if [ "$expected" = "$actual" ]; then
    echo "    OK"
  else
    echo "    checksum mismatch:" >&2
    echo "      expected $expected" >&2
    echo "      actual   $actual" >&2
    exit 1
  fi
fi

echo "==> Unpacking"
case "$ARCHIVE" in
*.gpg)
  gpg --decrypt "$ARCHIVE" >"$STAGE/archive.tar.zst"
  tar -C "$STAGE" -I zstd -xf "$STAGE/archive.tar.zst"
  rm -f "$STAGE/archive.tar.zst"
  ;;
*)
  tar -C "$STAGE" -I zstd -xf "$ARCHIVE"
  ;;
esac

ROOT="$(find "$STAGE" -maxdepth 1 -type d -name 'csw-backup-*' | head -n1)"
[ -n "$ROOT" ] || {
  echo "no csw-backup-* directory inside the archive" >&2
  exit 1
}
echo "    unpacked $(basename "$ROOT")"

echo "==> Restoring manifest entries"
restored=()
skipped=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$line" ] || continue
  [ "${line:0:1}" = "!" ] && continue

  if [[ "$line" == *"=>"* ]]; then
    dest="$(echo "${line##*=>}" | sed -e 's/^[[:space:]]*//')"
  else
    dest="$line"
  fi

  src="$ROOT/$dest"
  [ -e "$src" ] || continue

  # An empty directory counts as absent: running gpg or gh once before the
  # restore creates ~/.gnupg or ~/.config/gh, which would otherwise shadow the
  # backed-up one for good.
  if [ -d "$HOME/$dest" ] && [ -z "$(ls -A "$HOME/$dest" 2>/dev/null)" ]; then
    rmdir "$HOME/$dest"
  fi
  if [ -e "$HOME/$dest" ]; then
    skipped+=("$dest")
    continue
  fi

  mkdir -p "$HOME/$(dirname "$dest")"
  cp -a "$src" "$HOME/$dest"
  restored+=("$dest")
  echo "    $dest"
done <"$MANIFEST"

echo "==> Fixing permissions"
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -exec chmod 600 {} +
  find "$HOME/.ssh" -name '*.pub' -exec chmod 644 {} +
  echo "    ~/.ssh"
fi
if [ -d "$HOME/.gnupg" ]; then
  chmod 700 "$HOME/.gnupg"
  find "$HOME/.gnupg" -type f -exec chmod 600 {} +
  find "$HOME/.gnupg" -type d -exec chmod 700 {} +
  echo "    ~/.gnupg"
fi
if [ -d "$HOME/psps-secrets" ]; then
  chmod 700 "$HOME/psps-secrets"
  chmod 600 "$HOME/psps-secrets"/* 2>/dev/null || true
  echo "    ~/psps-secrets"
fi

echo "==> User services"
if [ -d "$HOME/.config/systemd/user" ]; then
  # The restored *.target.wants/ symlinks point at the old $HOME, so re-enable
  # each unit instead of trusting them.
  find "$HOME/.config/systemd/user" -name '*.target.wants' -type d -exec rm -rf {} +
  systemctl --user daemon-reload
  for unit in "$HOME"/.config/systemd/user/*.service; do
    [ -e "$unit" ] || continue
    name="$(basename "$unit")"
    if systemctl --user enable --now "$name" >/dev/null 2>&1; then
      echo "    enabled $name"
    else
      echo "    could not enable $name - check: systemctl --user status $name"
    fi
  done
else
  echo "    none restored"
fi

# 30-configure.sh tries this too, but the key only arrives with this restore,
# so on a fresh install the remote is still HTTPS by the time it runs.
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
  if [ -d "$DOTFILES_DIR/.git" ]; then
    case "$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null)" in
    https://github.com/*)
      git -C "$DOTFILES_DIR" remote set-url origin git@github.com:MrFacundo/dotfiles.git
      echo "==> dotfiles remote switched to SSH"
      ;;
    esac
  fi
fi

if [ ${#skipped[@]} -gt 0 ]; then
  echo
  echo "Already present, left untouched:"
  printf '  %s\n' "${skipped[@]}"
  echo "  (the originals are still in $ROOT until this script exits)"
fi

cat <<'CHECKLIST'

==> Manual steps left

  [ ] Firefox bookmarks
        The archive holds firefox/bookmarks.html.
        Firefox > Bookmarks > Manage Bookmarks > Import and Backup >
        Import Bookmarks from HTML.
        firefox/bookmarkbackups/*.jsonlz4 is a fallback if the HTML looks wrong.

  [ ] ssh
        ssh-add ~/.ssh/id_ed25519
        ssh-add ~/.ssh/bitbucket
        ssh -T git@github.com
        Check that ~/.ssh/config still matches the new machine.

  [ ] FoxyProxy
        Install the extension, then import
        firefox-addons-exports/FoxyProxy_*.json from the dotfiles repo and set
        the mode to "Proxy by Patterns". The SOCKS entry is localhost:9080 with
        Proxy DNS on, pattern *.codac.iter.org, and it needs iter-proxy.service
        running.

  [ ] GitHub CLI
        ~/.config/gh/hosts.yml was restored; verify with: gh auth status
        If it fails: gh auth login

  [ ] AI tooling
        ~/.claude/.credentials.json, ~/.claude.json and
        ~/.gemini/oauth_creds.json were restored. Start claude and gemini once
        to confirm, and re-authenticate if either rejects the token.
        copilot needs a fresh login.

  [ ] PSPS certificates
        ~/psps-secrets holds cafile.pem, client.crt and client.key.
        50-psps.sh puts them into coa-psps-protocol/secrets.

  [ ] KDE Store
        Install by hand: krohnkite, geometry change.

  [ ] Personal directories
        Code, notes, jenkins-lab, Documents, Downloads and Music were
        restored only if they did not already exist. Check the skip list above.

  [ ] Working repositories
        The repositories under ~/Code are cloned rather than backed up.
        50-psps.sh handles the CODAC ones; clone the rest by hand:
          git clone git@github.com:MrFacundo/react_training.git ~/Code/react_training

CHECKLIST

echo "Restore done. Next (optional): 50-psps.sh"
