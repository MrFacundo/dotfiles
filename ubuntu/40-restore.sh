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
  (cd "$(dirname "$ARCHIVE")" && sha256sum -c "$(basename "$ARCHIVE").sha256")
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
        Install by hand: krohnkite, virtual-desktops-only-on-primary,
        forceblur, rounded corners, geometry change.

  [ ] Personal directories
        Code, notes, jenkins-lab, Documents, Downloads, arch and Music were
        restored only if they did not already exist. Check the skip list above.

  [ ] Working repositories
        The repositories under ~/Code are cloned rather than backed up.
        50-psps.sh handles the CODAC ones; clone the rest by hand:
          git clone git@github.com:MrFacundo/react_training.git ~/Code/react_training

CHECKLIST

echo "Restore done. Next (optional): 50-psps.sh"
