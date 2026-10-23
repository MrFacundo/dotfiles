#!/usr/bin/env bash
# Runs the Ubuntu / KDE Neon setup phases in order.
#
#   ./install.sh                      everything, 00 through 40
#   ./install.sh --skip compliance    skip a phase (repeatable)
#   ./install.sh --only packages      run one phase and stop
#   ./install.sh --restore ARCHIVE    pass the backup archive to phase 40
#   ./install.sh --list               show the phases
#
# 50-psps.sh is deliberately not part of the default run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

phases=(
  "bootstrap:00-bootstrap.sh"
  "compliance:10-compliance.sh"
  "packages:20-packages.sh"
  "configure:30-configure.sh"
  "restore:40-restore.sh"
)

skip=()
only=""
archive=""

while [ $# -gt 0 ]; do
  case "$1" in
  --skip)
    skip+=("$2")
    shift 2
    ;;
  --only)
    only="$2"
    shift 2
    ;;
  --restore)
    archive="$2"
    shift 2
    ;;
  --list)
    printf '%s\n' "${phases[@]}" | sed 's/:/\t/'
    exit 0
    ;;
  -h | --help)
    sed -n '2,11p' "$0"
    exit 0
    ;;
  *)
    echo "unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

is_skipped() {
  local s
  for s in "${skip[@]:-}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

for entry in "${phases[@]}"; do
  name="${entry%%:*}"
  script="${entry##*:}"

  if [ -n "$only" ] && [ "$only" != "$name" ]; then continue; fi
  if is_skipped "$name"; then
    echo "### skipping $name"
    continue
  fi

  echo
  echo "###############################################################"
  echo "### $name  ($script)"
  echo "###############################################################"

  if [ "$name" = "restore" ]; then
    if [ -z "$archive" ]; then
      echo "### no --restore ARCHIVE given; skipping"
      continue
    fi
    bash "$SCRIPT_DIR/$script" "$archive"
  else
    bash "$SCRIPT_DIR/$script"
  fi
done

echo
echo "Done. Remaining manual steps are in ubuntu/README.md."
